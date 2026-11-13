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

    @Test("More lines of translation make the frame taller, with the text the same size")
    func moreLines() {
        // Small text: a line of translation is 90.8 pixels high and the original line 52.4.
        let small = { (lines: Int) in CaptionFrame.height(for: CaptionLayout(style: CaptionStyle(textSize: .small, lines: lines))) }
        #expect(small(3) == 404)
        #expect(small(4) == 494)
        let medium = { (lines: Int) in CaptionFrame.height(for: CaptionLayout(style: CaptionStyle(lines: lines))) }
        #expect(medium(3) == 478)
        #expect(abs(CaptionFrame.fontSize(columns: 24) - 94.56) < 0.01)
    }
}
