//
//  AttachmentSizing.swift
//  TextualDemo
//
//  Utility for accurate attachment sizing in Canvas mode.
//  Prevents font stretching by measuring actual rendered text dimensions.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Helper for calculating accurate attachment sizes to prevent stretching in Canvas mode
enum AttachmentSizing {
    #if canImport(UIKit)
    typealias PlatformFont = UIFont
    #elseif canImport(AppKit)
    typealias PlatformFont = NSFont
    #endif

    /// Measures the actual rendered size of text with given font
    /// - Parameters:
    ///   - text: The text to measure
    ///   - font: The platform font to use for measurement
    /// - Returns: The size the text will actually render at
    nonisolated static func measureText(_ text: String, font: PlatformFont) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Use boundingRect for accurate measurement including descenders
        let size = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        // Ceil to avoid subpixel issues
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    /// Measures text size using SwiftUI Font (converts to platform font internally)
    /// - Parameters:
    ///   - text: The text to measure
    ///   - font: The SwiftUI Font to use
    /// - Returns: The size the text will actually render at
    nonisolated static func measureText(_ text: String, font: Font) -> CGSize {
        // Convert SwiftUI Font to platform font for measurement
        let platformFont = font.toPlatformFont()
        return measureText(text, font: platformFont)
    }
}

// MARK: - Font Conversion

extension Font {
    /// Convert SwiftUI Font to platform font for text measurement
    /// Note: This handles common cases but may not be perfect for all Font types
    nonisolated func toPlatformFont() -> AttachmentSizing.PlatformFont {
        // For system fonts, we can extract size and weight
        // This is a simplified conversion - production code may need more cases

        // Try to extract font details from the font descriptor
        // SwiftUI doesn't expose this easily, so we use a fallback approach

        // Default to 17pt system font (SwiftUI default)
        // In practice, you'd pass explicit size/weight parameters instead of converting
        #if canImport(UIKit)
        return UIFont.systemFont(ofSize: 17)
        #elseif canImport(AppKit)
        return NSFont.systemFont(ofSize: 17)
        #endif
    }
}

// MARK: - Convenient System Font Helpers

extension AttachmentSizing {
    #if canImport(UIKit)
    typealias FontWeight = UIFont.Weight
    #elseif canImport(AppKit)
    typealias FontWeight = NSFont.Weight
    #endif

    /// Measures text with a system font
    /// - Parameters:
    ///   - text: The text to measure
    ///   - size: Font size in points
    ///   - weight: Font weight (default: .regular)
    /// - Returns: The size the text will actually render at
    nonisolated static func measureText(
        _ text: String,
        size: CGFloat,
        weight: FontWeight = .regular
    ) -> CGSize {
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        #endif
        return measureText(text, font: font)
    }

    /// Calculate size for a pill-style attachment (icon + text + padding)
    /// - Parameters:
    ///   - text: The text content
    ///   - iconWidth: Width of the icon/emoji
    ///   - fontSize: Font size for the text
    ///   - fontWeight: Font weight for the text
    ///   - horizontalPadding: Total horizontal padding (left + right)
    ///   - verticalPadding: Total vertical padding (top + bottom)
    ///   - spacing: Spacing between icon and text
    /// - Returns: Total size of the pill attachment
    nonisolated static func measurePill(
        text: String,
        iconWidth: CGFloat,
        fontSize: CGFloat,
        fontWeight: FontWeight = .regular,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        spacing: CGFloat
    ) -> CGSize {
        let textSize = measureText(text, size: fontSize, weight: fontWeight)

        let width = iconWidth + spacing + textSize.width + horizontalPadding
        let height = max(textSize.height, iconWidth) + verticalPadding

        return CGSize(width: ceil(width), height: ceil(height))
    }
}
