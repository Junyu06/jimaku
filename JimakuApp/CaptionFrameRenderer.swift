import CoreMedia
import CoreVideo
import JimakuCore
import UIKit

/// Draws caption rows into video frames for the Picture in Picture window.
///
/// Picture in Picture can only show video, so each caption is rendered as one frame.
struct CaptionFrameRenderer {
    /// Pixel size of a frame. The floating window takes its aspect ratio from this.
    static let frameSize = CGSize(width: 1200, height: 400)

    private static let padding: CGFloat = 36
    private static let rowSpacing: CGFloat = 10
    private static let background = UIColor(white: 0.07, alpha: 1)

    private static let meterHeight: CGFloat = 10
    private static let meterTrack = UIColor(white: 1, alpha: 0.14)
    private static let meterFill = UIColor(red: 0.98, green: 0.82, blue: 0.25, alpha: 1)

    /// - Parameter audioLevel: 0...1, drawn as a thin meter along the bottom so the
    ///   reader can see that audio is arriving. Nil hides the meter.
    func makeSampleBuffer(
        for lines: CaptionLines,
        style: CaptionStyle = CaptionStyle(),
        audioLevel: Double? = nil
    ) -> CMSampleBuffer? {
        guard let pixelBuffer = makePixelBuffer() else { return nil }
        draw(lines.rows(in: style.mode), scale: style.textSize.scale, audioLevel: audioLevel, into: pixelBuffer)
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

    private func draw(_ rows: [CaptionRow], scale: Double, audioLevel: Double?, into pixelBuffer: CVPixelBuffer) {
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

        var content = CGRect(origin: .zero, size: size).insetBy(dx: Self.padding, dy: Self.padding)
        if let audioLevel {
            let (meter, rest) = content.divided(atDistance: Self.meterHeight, from: .maxYEdge)
            drawMeter(level: audioLevel, in: meter)
            content = rest.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: Self.rowSpacing * 2, right: 0))
        }
        for (row, rect) in zip(rows, rects(for: rows, in: content)) {
            draw(row, scale: scale, in: rect)
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

    /// Splits the content area between rows. A secondary row gets about a third of
    /// the height; the primary row gets the rest.
    private func rects(for rows: [CaptionRow], in content: CGRect) -> [CGRect] {
        guard rows.count == 2 else { return rows.map { _ in content } }
        let secondaryHeight = (content.height - Self.rowSpacing) * 0.36
        let (top, bottom) = content.divided(atDistance: secondaryHeight, from: .minYEdge)
        let primary = bottom.inset(by: UIEdgeInsets(top: Self.rowSpacing, left: 0, bottom: 0, right: 0))
        return rows.map { $0.role == .secondary ? top : primary }
    }

    private func draw(_ row: CaptionRow, scale: Double, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        let (largest, smallest, weight, color): (CGFloat, CGFloat, UIFont.Weight, UIColor) =
            switch row.role {
            case .primary: (104, 44, .semibold, .white)
            case .secondary: (60, 30, .regular, UIColor(white: 1, alpha: 0.62))
            }

        // Start from the user's text size and shrink until the text fits the row.
        var fontSize = max(largest * scale, smallest)
        var text = NSAttributedString()
        var textHeight: CGFloat = 0
        while true {
            text = NSAttributedString(
                string: row.text,
                attributes: [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
                    .foregroundColor: color,
                    .paragraphStyle: paragraph,
                ]
            )
            textHeight = ceil(
                text.boundingRect(
                    with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height
            )
            if textHeight <= rect.height || fontSize <= smallest { break }
            fontSize -= 4
        }

        let drawHeight = min(textHeight, rect.height)
        let target = CGRect(x: rect.minX, y: rect.midY - drawHeight / 2, width: rect.width, height: drawHeight)
        text.draw(with: target, options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], context: nil)
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
