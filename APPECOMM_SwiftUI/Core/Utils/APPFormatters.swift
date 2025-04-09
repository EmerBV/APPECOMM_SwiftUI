//
//  APPFormatters.swift
//  APPECOMM_SwiftUI
//
//  Created by Emerson Balahan Varona on 27/3/25.
//

import Foundation

class APPFormatters {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        let currencyCode = getCurrencyCode()
        formatter.currencyCode = currencyCode
        
        return formatter
    }()
    
    private static func getCurrencyCode() -> String {
        let countryCode = Locale.current.regionCode ?? "US"
        
        let currencyMap: [String: String] = [
            "US": "USD",
            "ES": "EUR",
            "MX": "MXN",
            "AR": "ARS",
            "CL": "CLP",
            "CO": "COP",
            "PE": "PEN",
            "BR": "BRL",
            "UY": "UYU",
            "PY": "PYG",
            "BO": "BOB",
            "EC": "USD",
            "VE": "USD",
            "GT": "GTQ",
            "SV": "USD",
            "HN": "HNL",
            "NI": "NIO",
            "CR": "CRC",
            "PA": "USD",
            "DO": "DOP",
            "PR": "USD",
            "CU": "CUP",
            "HT": "HTG",
            "JM": "JMD",
            "TT": "TTD",
            "BB": "BBD",
            "GD": "XCD",
            "LC": "XCD",
            "VC": "XCD",
            "AG": "XCD",
            "KN": "XCD",
            "DM": "XCD",
            "BZ": "BZD",
            "SR": "SRD",
            "GY": "GYD",
            "GF": "EUR",
            "CA": "CAD",
            "GB": "GBP",
            "FR": "EUR",
            "DE": "EUR",
            "IT": "EUR",
            "PT": "EUR",
            "NL": "EUR",
            "BE": "EUR",
            "IE": "EUR",
            "GR": "EUR",
            "AT": "EUR",
            "FI": "EUR",
            "SE": "SEK",
            "DK": "DKK",
            "NO": "NOK",
            "CH": "CHF",
            "AU": "AUD",
            "NZ": "NZD",
            "JP": "JPY",
            "CN": "CNY",
            "KR": "KRW",
            "IN": "INR",
            "RU": "RUB",
            "ZA": "ZAR"
        ]
        
        return currencyMap[countryCode] ?? "USD"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter
    }()
    
    private static let dateFormats: [String] = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd"
    ]
    
    public static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    public static func formattedPrice(_ price: Decimal) -> String {
        return currencyFormatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
    
    public static func formattedDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    public static func formattedDateString(from dateString: String) -> String {
        // Convert API date string to a formatted date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // Adjust based on API date format
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return dateFormatter.string(from: date)
            }
        }
        
        return dateString // Return original if parsing fails
    }
    
}
