import JimakuCore
import Testing

@Suite("CaptionFrame")
struct CaptionFrameTests {
    private static var layouts: [(CaptionStyle, CaptionLayout)] {
        var all: [(CaptionStyle, CaptionLayout)] = []
        for size in CaptionStyle.TextSize.allCases {
            for mode in CaptionStyle.Mode.allCases {
                for lines in CaptionStyle.lineChoices {
                    for available in [true, false] {
                        let style = CaptionStyle(textSize: size, mode: mode, lines: lines)
                        all.append((style, CaptionLayout(style: style, translationAvailable: available)))
                    }
                }
            }
        }
        return all
    }

    @Test("With two lines of translation the frame is 1200 by 400, at every size and in both modes")
    func twoLines() {
        for (style, layout) in Self.layouts where style.lines == 2 {
            #expect(CaptionFrame.height(for: layout) == 400)
        }
        #expect(CaptionFrame.width == 1200)
    }

    @Test("Every layout's rows fit its frame at their full size")
    func rowsFit() {
        for (_, layout) in Self.layouts {
            let height = CaptionFrame.height(for: layout)
            #expect(CaptionFrame.rowsHeight(for: layout) <= CaptionFrame.rowsArea(inFrameOfHeight: height))
        }
    }

    @Test("A frame is only as much taller than 400 as its rows need, to the next even pixel")
    func noTallerThanNeeded() {
        for (_, layout) in Self.layouts {
            let height = CaptionFrame.height(for: layout)
            #expect(height.truncatingRemainder(dividingBy: 2) == 0)
            if height > 400 {
                #expect(CaptionFrame.rowsHeight(for: layout) > CaptionFrame.rowsArea(inFrameOfHeight: height - 2))
            }
        }
    }

    @Test("More lines of translation make the frame taller once they no longer fit, with the text the same size")
    func moreLines() {
        let height = { (size: CaptionStyle.TextSize, lines: Int) in
            CaptionFrame.height(for: CaptionLayout(style: CaptionStyle(textSize: size, lines: lines)))
        }
        // Small text: a line of translation is 57.2 pixels high and the original line 40.6.
        #expect(height(.small, 4) == 400)
        #expect(height(.small, 5) == 438)
        // Medium: 67.2 and 46.8.
        #expect(height(.medium, 3) == 400)
        #expect(height(.medium, 5) == 494)
        // Large: 77.2 and 51.5.
        #expect(height(.large, 4) == 472)
        #expect(height(.large, 5) == 548)
    }

    @Test("At the small size twenty-seven Chinese characters fit a line of translation")
    func smallText() {
        let row = CaptionLayout(style: CaptionStyle(textSize: .small)).translation
        #expect(row?.columns == 54)
        #expect(abs(CaptionFrame.fontSize(columns: 54) - 40.86) < 0.01)
    }

    @Test("Text has room around it: forty pixels at each edge, and lines set at 1.4 times the text size")
    func room() {
        #expect(CaptionFrame.padding == 40)
        #expect(CaptionFrame.textWidth == 1120)
        #expect(CaptionFrame.leading == 1.4)
    }
}
