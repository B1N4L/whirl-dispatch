//
//  AppDateFormatter.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-30.
//

import Foundation

enum AppDateFormatter: Sendable {
    private static let isoFractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoStandardFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let fallbackDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let lock = NSLock()

    static func parse(_ string: String?) -> Date? {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return nil
        }

        lock.lock()
        defer { lock.unlock() }

        if let date = isoFractionalFormatter.date(from: s) {
            return date
        }
        if let date = isoStandardFormatter.date(from: s) {
            return date
        }
        if let date = fallbackDateFormatter.date(from: s) {
            return date
        }
        if let date = dateOnlyFormatter.date(from: s) {
            return date
        }
        return nil
    }

    static func formatDate(_ string: String?) -> String {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "N/A"
        }
        guard let date = parse(s) else { return s }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func formatTime(_ string: String?) -> String {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "N/A"
        }
        guard let date = parse(s) else { return s }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func formatDateTime(_ string: String?) -> String {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "N/A"
        }
        guard let date = parse(s) else { return s }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    static func formatFullDateTime(_ string: String?) -> String {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "N/A"
        }
        guard let date = parse(s) else { return s }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy, h:mm a"
        return formatter.string(from: date)
    }

    static func formatWindow(start: String?, end: String?) -> String {
        guard let s = start?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return "N/A"
        }
        guard let sDate = parse(s) else {
            let e = end?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return e.isEmpty ? s : "\(s) to \(e)"
        }

        let startFormatted = formatDateTime(s)
        guard let e = end?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty, let eDate = parse(e) else {
            return startFormatted
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        if Calendar.current.isDate(sDate, inSameDayAs: eDate) {
            let endTimeStr = timeFormatter.string(from: eDate)
            return "\(startFormatted) – \(endTimeStr)"
        } else {
            let endFormatted = formatDateTime(e)
            return "\(startFormatted) – \(endFormatted)"
        }
    }
}
