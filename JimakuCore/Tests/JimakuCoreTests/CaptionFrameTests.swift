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
        // Small text: a line of translation is 68.1 pixels high and the original line 42.6.
        #expect(height(.small, 4) == 400)
        #expect(height(.small, 5) == 462)
        // Medium: 90.8 and 52.4.
        #expect(height(.medium, 3) == 404)
        #expect(height(.medium, 5) == 586)
        // Large: 113.5 and 59.2.
        #expect(height(.large, 3) == 478)
    }

    @Test("At the small size twenty Chinese characters fit a line of translation")
    func smallText() {
        let row = CaptionLayout(style: CaptionStyle(textSize: .small)).translation
        #expect(row?.columns == 40)
        #expect(abs(CaptionFrame.fontSize(columns: 40) - 56.74) < 0.01)
    }
}
