import CoreMedia
import CoreVideo
import JimakuCore
import UIKit
import os

/// Draws caption rows into video frames for the Picture in Picture window.
///
/// Picture in Picture can only show video, so each caption is rendered as one frame.
///
/// Every line has a fixed place in the frame, and the text size follows from how
/// many columns a row holds. So a character that has been drawn stays where it is
/// until its line rolls up; nothing is re-centered or shrunk as text arrives.
///
/// For that to hold, lines must be broken by how wide the characters really are in
/// the font used here. `glyphWidths(for:)` measures it.
struct CaptionFrameRenderer {
    /// Pixel size of a frame. The floating window takes its aspect ratio from this.
    static let frameSize = CGSize(width: 1200, height: 400)

    private static let padding: CGFloat = 24
    private static let rowSpacing: CGFloat = 10
    private static let background = UIColor(white: 0.07, alpha: 1)

    /// The share of the nominal size the font is drawn at, leaving a little slack
    /// at the end of a full line.
    private static let fill: CGFloat = 0.985

    /// Line height as a multiple of the font size.
    private static let leading: CGFloat = 1.2

    private static let log = Logger(subsystem: "Jimaku", category: "captions")

    private static let meterHeight: CGFloat = 10
    private static let meterTrack = UIColor(white: 1, alpha: 0.14)
    private static let meterFill = UIColor(red: 0.98, green: 0.82, blue: 0.25, alpha: 1)

    /// - Parameter audioLevel: 0...1, drawn as a thin meter along the bottom so the
    ///   reader can see that audio is arriving. Nil hides the meter.
    func makeSampleBuffer(for content: CaptionContent, audioLevel: Double? = nil) -> CMSampleBuffer? {
        guard let pixelBuffer = makePixelBuffer() else { return nil }
        draw(content, audioLevel: audioLevel, into: pixelBuffer)
        return makeSampleBuffer(from: pixelBuffer)
    }

    private func makePixelBuffer() -> CVPixelBuffer? {
        let attributes: [CFString: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(Self.frameSize.width),
            Int(Self.frameSize.height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        return pixelBuffer
    }

    private func draw(_ content: CaptionContent, audioLevel: Double?, into pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        let size = Self.frameSize
        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            )
        else { return }

        context.setFillColor(Self.background.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // UIKit draws text with a top-left origin; Core Graphics starts bottom-left.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }

        var area = CGRect(origin: .zero, size: size).insetBy(dx: Self.padding, dy: Self.padding)
        // The meter's space is always set aside, so captions do not move when it
        // comes and goes.
        let (meter, rest) = area.divided(atDistance: Self.meterHeight, from: .maxYEdge)
        area = rest.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: Self.rowSpacing, right: 0))
        if let audioLevel {
            drawMeter(level: audioLevel, in: meter)
        }
        switch content {
        case .rows(let rows): draw(rows, in: area)
        case .notice(let text): draw(notice: text, in: area)
        }
    }

    private func drawMeter(level: Double, in rect: CGRect) {
        let radius = rect.height / 2
        Self.meterTrack.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
        let clamped = min(max(level, 0), 1)
        guard clamped > 0 else { return }
        var fill = rect
        fill.size.width = max(rect.width * clamped, rect.height)
        Self.meterFill.setFill()
        UIBezierPath(roundedRect: fill, cornerRadius: radius).fill()
    }

    /// Draws the rows as one block, centered vertically. The block's size depends
    /// only on how many lines the rows have room for, not on how many are filled.
    private func draw(_ rows: [CaptionRow], in area: CGRect) {
        let sizes = rows.map { Self.fontSize(columns: $0.columns, width: area.width) }
        let height =
            zip(rows, sizes).reduce(0) { $0 + CGFloat($1.0.lineCount) * $1.1 * Self.leading }
            + Self.rowSpacing * CGFloat(max(rows.count - 1, 0))
        // Layouts are chosen to fit; this only guards against one that does not.
        let fit = min(1, area.height / max(height, 1))

        var top = area.minY + (area.height - height * fit) / 2
        for (row, size) in zip(rows, sizes) {
            let fontSize = size * fit
            let lineHeight = fontSize * Self.leading
            for (index, line) in row.lines.prefix(row.lineCount).enumerated() {
                let slot = CGRect(x: area.minX, y: top + CGFloat(index) * lineHeight, width: area.width, height: lineHeight)
                draw(line, role: row.role, fontSize: fontSize, in: slot)
            }
            top += CGFloat(row.lineCount) * lineHeight + Self.rowSpacing * fit
        }
    }

    /// The font size at which `columns` columns fill the width: a wide character
    /// is as wide as the font size, and takes two columns.
    private static func fontSize(columns: Int, width: CGFloat) -> CGFloat {
        width * 2 / CGFloat(max(columns, 2)) * fill
    }

    /// The width captions are drawn in, in pixels.
    private static var textWidth: CGFloat { frameSize.width - padding * 2 }

    private static func weight(for role: CaptionRow.Role) -> UIFont.Weight {
        switch role {
        case .primary: .semibold
        case .secondary: .regular
        }
    }

    /// How wide the letters, digits, and marks of ASCII are, in columns, in the
    /// font and at the size a row with this role and this many columns is drawn.
    /// The system font spaces its letters differently at different sizes, so the
    /// size matters. Other narrow characters, such as accented letters, are taken
    /// to be as wide as the widest common letters.
    static func glyphWidths(role: CaptionRow.Role, columns: Int) -> GlyphWidths {
        let size = fontSize(columns: columns, width: textWidth)
        let font = UIFont.systemFont(ofSize: size, weight: weight(for: role))
        let column = textWidth / CGFloat(max(columns, 2))
        var narrow: [Character: Double] = [:]
        for scalar in (0x20...0x7E).compactMap(Unicode.Scalar.init) {
            let character = Character(scalar)
            let advance = NSAttributedString(string: String(character), attributes: [.font: font]).size().width
            narrow[character] = Double(advance / column)
        }
        return GlyphWidths(narrow: narrow, unknownNarrow: 1.5)
    }

    private func draw(_ line: CaptionLine, role: CaptionRow.Role, fontSize: CGFloat, in slot: CGRect) {
        let weight = Self.weight(for: role)
        let (settled, tentative): (UIColor, UIColor) =
            switch role {
            case .primary: (.white, UIColor(white: 1, alpha: 0.5))
            case .secondary: (UIColor(white: 1, alpha: 0.66), UIColor(white: 1, alpha: 0.4))
            }

        func text(at size: CGFloat) -> NSAttributedString {
            let font = UIFont.systemFont(ofSize: size, weight: weight)
            let text = NSMutableAttributedString(
                string: line.settled,
                attributes: [.font: font, .foregroundColor: settled]
            )
            text.append(
                NSAttributedString(string: line.tentative, attributes: [.font: font, .foregroundColor: tentative])
            )
            return text
        }

        // Lines are broken by measured widths, so this should not happen. It still
        // can with characters that were not measured: such a line is drawn a
        // little smaller rather than cut off, and its text then does move.
        var drawn = text(at: fontSize)
        var drawnSize = drawn.size()
        if drawnSize.width > slot.width {
            Self.log.info("a caption line was \(drawnSize.width - slot.width, privacy: .public) px too wide and was drawn smaller")
            drawn = text(at: fontSize * slot.width / drawnSize.width)
            drawnSize = drawn.size()
        }
        drawn.draw(at: CGPoint(x: slot.minX, y: slot.midY - drawnSize.height / 2))
    }

    private func draw(notice: String, in area: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        var fontSize: CGFloat = 72
        var text = NSAttributedString()
        var size = CGSize.zero
        repeat {
            text = NSAttributedString(
                string: notice,
                attributes: [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                    .foregroundColor: UIColor(white: 1, alpha: 0.8),
                    .paragraphStyle: paragraph,
                ]
            )
            size = text.size()
            fontSize -= 4
        } while size.width > area.width && fontSize >= 32
        text.draw(at: CGPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2))
    }

    private func makeSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var format: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &format
        )
        guard let format else { return nil }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard let sampleBuffer else { return nil }

        // Show the frame as soon as it arrives instead of waiting for its timestamp.
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
            CFArrayGetCount(attachments) > 0
        {
            let first = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(
                first,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }
        return sampleBuffer
    }
}
