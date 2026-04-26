import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outDir = root.appendingPathComponent("Demo/Final")
let iconURL = root.appendingPathComponent("MenuBarQuotes/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let canvas = CGSize(width: 1574, height: 1008)

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: y, width: w, height: h)
}

func drawText(
    _ text: String,
    in r: CGRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = NSColor(hex: 0x111827),
    align: NSTextAlignment = .left,
    font: NSFont? = nil,
    lineHeight: CGFloat? = nil
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font ?? NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSString(string: text).draw(in: r, withAttributes: attrs)
}

func rounded(_ r: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func line(from: CGPoint, to: CGPoint, color: NSColor = NSColor(hex: 0xd8dee7), width: CGFloat = 1) {
    color.setStroke()
    let p = NSBezierPath()
    p.lineWidth = width
    p.move(to: from)
    p.line(to: to)
    p.stroke()
}

func shadow(alpha: CGFloat = 0.12, blur: CGFloat = 26, offset: CGSize = CGSize(width: 0, height: -10), _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(alpha)
    s.shadowBlurRadius = blur
    s.shadowOffset = offset
    s.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func background() {
    NSColor(hex: 0xf7f7f4).setFill()
    rect(0, 0, canvas.width, canvas.height).fill()
    NSColor(hex: 0xefeee9).setFill()
    rect(0, 0, canvas.width, 128).fill()
    line(from: CGPoint(x: 0, y: 128), to: CGPoint(x: canvas.width, y: 128), color: NSColor(hex: 0xe1dfd7))
}

func header(_ title: String, _ subtitle: String) {
    drawText(title, in: rect(112, 822, 570, 68), size: 44, weight: .semibold, color: NSColor(hex: 0x151515), lineHeight: 52)
    drawText(subtitle, in: rect(114, 768, 610, 38), size: 20, color: NSColor(hex: 0x6c6a63), lineHeight: 28)
}

func label(_ text: String, at point: CGPoint, width: CGFloat = 240) {
    drawText(text.uppercased(), in: rect(point.x, point.y, width, 18), size: 11, weight: .semibold, color: NSColor(hex: 0x8b887d))
}

func window(_ r: CGRect, title: String) {
    shadow(alpha: 0.13, blur: 34, offset: CGSize(width: 0, height: -12)) {
        rounded(r, radius: 16, fill: NSColor(hex: 0xfbfbfa), stroke: NSColor(hex: 0xd8d6ce))
    }
    rounded(rect(r.minX, r.maxY - 48, r.width, 48), radius: 16, fill: NSColor(hex: 0xefeee9))
    rounded(rect(r.minX, r.maxY - 60, r.width, 24), radius: 0, fill: NSColor(hex: 0xefeee9))
    for (i, color) in [0xff5f57, 0xffbd2e, 0x28c840].enumerated() {
        rounded(rect(r.minX + 20 + CGFloat(i) * 22, r.maxY - 29, 11, 11), radius: 5.5, fill: NSColor(hex: UInt32(color)))
    }
    drawText(title, in: rect(r.midX - 150, r.maxY - 34, 300, 18), size: 13, weight: .medium, color: NSColor(hex: 0x69665f), align: .center)
}

func desktopMenuBar(y: CGFloat, quote: String, quoteColor: NSColor = NSColor(hex: 0x1b1b1b), bold: Bool = false) {
    shadow(alpha: 0.09, blur: 20, offset: CGSize(width: 0, height: -5)) {
        rounded(rect(86, y, 1402, 42), radius: 13, fill: NSColor.white.withAlphaComponent(0.88), stroke: NSColor(hex: 0xdedcd5))
    }
    drawText("Finder", in: rect(122, y + 12, 76, 18), size: 14, weight: .semibold, color: NSColor(hex: 0x252525))
    drawText("File   Edit   View   Window   Help", in: rect(204, y + 12, 370, 18), size: 14, color: NSColor(hex: 0x4c4a45))
    drawText(quote, in: rect(560, y + 10, 560, 22), size: 15, weight: bold ? .bold : .regular, color: quoteColor, align: .center)
    drawText("Wi-Fi   100%   Sun 9:41 AM", in: rect(1212, y + 12, 236, 18), size: 14, color: NSColor(hex: 0x4c4a45), align: .right)
}

func button(_ title: String, _ r: CGRect, primary: Bool = false, disabled: Bool = false) {
    let fill = primary ? NSColor(hex: 0x171717) : NSColor(hex: 0xffffff)
    let stroke = primary ? NSColor(hex: 0x171717) : NSColor(hex: 0xcfcac0)
    rounded(r, radius: 6, fill: disabled ? NSColor(hex: 0xefeee9) : fill, stroke: stroke)
    drawText(title, in: r.insetBy(dx: 8, dy: 6), size: 13, weight: .medium, color: primary ? .white : (disabled ? NSColor(hex: 0xaaa69d) : NSColor(hex: 0x2b2a27)), align: .center)
}

func manageWindow(_ r: CGRect, selected: Int = 1, styleAccent: NSColor = NSColor(hex: 0x2b8178)) {
    window(r, title: "Manage Quotes")
    let left = r.minX + 26
    let top = r.maxY - 84
    rounded(rect(left, top, r.width - 132, 32), radius: 6, fill: .white, stroke: NSColor(hex: 0xd5d1c8))
    drawText("Simplicity is the ultimate sophistication.", in: rect(left + 12, top + 8, r.width - 164, 18), size: 13, color: NSColor(hex: 0x6c6a63))
    button("Add", rect(r.maxX - 86, top, 60, 32), primary: true)

    let table = rect(left, r.minY + 92, r.width - 52, 286)
    rounded(table, radius: 8, fill: .white, stroke: NSColor(hex: 0xd8d4cb))
    let quotes = [
        "Great things are done by a series of small things brought together.",
        "Simplicity is the ultimate sophistication.",
        "The details are not the details. They make the design.",
        "Make each day your masterpiece.",
        "Energy and persistence conquer all things."
    ]
    for (idx, q) in quotes.enumerated() {
        let rowY = table.maxY - 48 - CGFloat(idx) * 50
        if idx == selected {
            rounded(rect(table.minX + 8, rowY + 7, table.width - 16, 34), radius: 7, fill: styleAccent.withAlphaComponent(0.11))
        }
        if idx > 0 {
            line(from: CGPoint(x: table.minX + 14, y: rowY + 49), to: CGPoint(x: table.maxX - 14, y: rowY + 49), color: NSColor(hex: 0xe7e3da))
        }
        drawText(q, in: rect(table.minX + 18, rowY + 16, table.width - 36, 18), size: 13, color: NSColor(hex: 0x32302b))
    }

    let y = r.minY + 40
    var x = left
    for t in ["Edit", "Delete", "Import", "Export", "Style...", "Done"] {
        let w: CGFloat = t == "Style..." ? 70 : 62
        button(t, rect(x, y, w, 30), primary: t == "Done")
        x += w + 10
    }
    drawText("Rotation", in: rect(r.maxX - 222, y + 7, 70, 18), size: 13, color: NSColor(hex: 0x6c6a63), align: .right)
    rounded(rect(r.maxX - 144, y, 46, 30), radius: 6, fill: .white, stroke: NSColor(hex: 0xd5d1c8))
    drawText("2", in: rect(r.maxX - 136, y + 7, 28, 18), size: 13, color: NSColor(hex: 0x2b2a27), align: .right)
    drawText("h", in: rect(r.maxX - 91, y + 7, 16, 18), size: 13, color: NSColor(hex: 0x6c6a63))
    rounded(rect(r.maxX - 70, y, 46, 30), radius: 6, fill: .white, stroke: NSColor(hex: 0xd5d1c8))
    drawText("30", in: rect(r.maxX - 64, y + 7, 30, 18), size: 13, color: NSColor(hex: 0x2b2a27), align: .right)
    drawText("m", in: rect(r.maxX - 18, y + 7, 16, 18), size: 13, color: NSColor(hex: 0x6c6a63))
}

func menuPanel(_ r: CGRect) {
    shadow(alpha: 0.16, blur: 28, offset: CGSize(width: 0, height: -10)) {
        rounded(r, radius: 14, fill: .white, stroke: NSColor(hex: 0xd5d1c8))
    }
    drawText("Make each day your masterpiece.", in: rect(r.minX + 22, r.maxY - 44, r.width - 44, 20), size: 14, color: NSColor(hex: 0x6c6a63))
    line(from: CGPoint(x: r.minX + 16, y: r.maxY - 60), to: CGPoint(x: r.maxX - 16, y: r.maxY - 60), color: NSColor(hex: 0xe2ded6))
    rounded(rect(r.minX + 10, r.maxY - 106, r.width - 20, 34), radius: 7, fill: NSColor(hex: 0x171717, alpha: 0.08))
    drawText("Next Quote Now", in: rect(r.minX + 26, r.maxY - 98, 210, 18), size: 15, weight: .medium, color: NSColor(hex: 0x171717))
    drawText("Manage Quotes...", in: rect(r.minX + 26, r.maxY - 140, 210, 18), size: 15, color: NSColor(hex: 0x33312d))
    drawText("Quit Menu Bar Quotes", in: rect(r.minX + 26, r.maxY - 178, 230, 18), size: 15, color: NSColor(hex: 0x33312d))
}

func stylePopover(_ r: CGRect) {
    shadow(alpha: 0.15, blur: 26, offset: CGSize(width: 0, height: -10)) {
        rounded(r, radius: 12, fill: NSColor(hex: 0xffffff), stroke: NSColor(hex: 0xd5d1c8))
    }
    let rows = [("Font", "Rounded"), ("Size", "Large"), ("Color", "Teal")]
    for (i, row) in rows.enumerated() {
        let y = r.maxY - 38 - CGFloat(i) * 38
        drawText(row.0, in: rect(r.minX + 16, y, 48, 18), size: 13, color: NSColor(hex: 0x7b776d), align: .right)
        rounded(rect(r.minX + 76, y - 5, r.width - 94, 28), radius: 6, fill: NSColor(hex: 0xf7f6f2), stroke: NSColor(hex: 0xded9d0))
        drawText(row.1, in: rect(r.minX + 88, y + 1, r.width - 124, 18), size: 13, color: NSColor(hex: 0x282723))
    }
    rounded(rect(r.minX + 80, r.minY + 17, 16, 16), radius: 4, fill: NSColor(hex: 0x2b8178))
    drawText("Bold", in: rect(r.minX + 106, r.minY + 15, 80, 18), size: 13, color: NSColor(hex: 0x282723))
}

func fileCard(_ r: CGRect, badge: String, title: String, lines: [String], accent: NSColor) {
    shadow(alpha: 0.08, blur: 20, offset: CGSize(width: 0, height: -7)) {
        rounded(r, radius: 14, fill: .white, stroke: NSColor(hex: 0xd9d5cc))
    }
    rounded(rect(r.minX + 24, r.maxY - 66, 56, 42), radius: 10, fill: accent.withAlphaComponent(0.12), stroke: accent.withAlphaComponent(0.3))
    drawText(badge, in: rect(r.minX + 32, r.maxY - 52, 40, 16), size: 12, weight: .semibold, color: accent, align: .center)
    drawText(title, in: rect(r.minX + 98, r.maxY - 52, r.width - 122, 20), size: 17, weight: .semibold, color: NSColor(hex: 0x25231f))
    for (i, text) in lines.enumerated() {
        let y = r.maxY - 116 - CGFloat(i) * 42
        rounded(rect(r.minX + 28, y, r.width - 56, 26), radius: 6, fill: NSColor(hex: 0xf5f4ef))
        drawText(text, in: rect(r.minX + 42, y + 7, r.width - 84, 14), size: 11, color: NSColor(hex: 0x6f6a61))
    }
}

func render(_ filename: String, draw: () -> Void) {
    let image = NSImage(size: canvas)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw()
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Unable to render \(filename)")
    }
    try! png.write(to: outDir.appendingPathComponent(filename))
}

let appIcon = NSImage(contentsOf: iconURL)

render("01-menu-bar-quotes.png") {
    background()
    header("Quotes, quietly visible.", "A favorite line in the macOS menu bar.")
    desktopMenuBar(y: 724, quote: "Simplicity is the ultimate sophistication.")
    shadow(alpha: 0.12, blur: 30, offset: CGSize(width: 0, height: -10)) {
        rounded(rect(370, 350, 834, 226), radius: 24, fill: NSColor.white.withAlphaComponent(0.88), stroke: NSColor(hex: 0xd8d4cb))
    }
    if let appIcon {
        appIcon.draw(in: rect(444, 418, 92, 92), from: .zero, operation: .sourceOver, fraction: 1)
    }
    drawText("Menu Bar Quotes", in: rect(574, 454, 430, 36), size: 32, weight: .semibold)
    drawText("Short quotes stay present while the app stays out of the way.", in: rect(576, 414, 500, 26), size: 18, color: NSColor(hex: 0x6c6a63))
    label("Status item", at: CGPoint(x: 730, y: 682), width: 120)
}

render("02-manage-library.png") {
    background()
    header("Keep a clean quote library.", "Add, edit, delete, import, and export.")
    manageWindow(rect(270, 228, 780, 560), selected: 2)
    label("Selected quote", at: CGPoint(x: 1096, y: 590))
    drawText("Edit in place, then save or remove the selected row.", in: rect(1096, 548, 290, 58), size: 21, weight: .medium, color: NSColor(hex: 0x22211e), lineHeight: 29)
    line(from: CGPoint(x: 1030, y: 584), to: CGPoint(x: 870, y: 524), color: NSColor(hex: 0xb9b2a5), width: 1.4)
    label("Portable", at: CGPoint(x: 1096, y: 414))
    drawText("Import from files. Export a plain text backup.", in: rect(1096, 372, 290, 58), size: 21, weight: .medium, color: NSColor(hex: 0x22211e), lineHeight: 29)
}

render("03-import-export.png") {
    background()
    header("Bring quotes with you.", "Import TXT, CSV, or Markdown. Export TXT.")
    fileCard(rect(144, 398, 288, 250), badge: "TXT", title: "focus.txt", lines: ["Deep work beats busy work", "Small steps compound", "Make each day count"], accent: NSColor(hex: 0x476f9f))
    fileCard(rect(464, 398, 288, 250), badge: "CSV", title: "quotes.csv", lines: ["Stay hungry", "Energy and persistence", "Simplicity wins"], accent: NSColor(hex: 0x9a6b24))
    fileCard(rect(784, 398, 288, 250), badge: "MD", title: "notes.md", lines: ["## Favorites", "- Details make the design", "- Ship the useful thing"], accent: NSColor(hex: 0x7b5b95))
    fileCard(rect(1104, 398, 288, 250), badge: "TXT", title: "export.txt", lines: ["Simplicity is ultimate", "The details make design", "Great things in steps"], accent: NSColor(hex: 0x2b8178))
    label("Import", at: CGPoint(x: 254, y: 302), width: 120)
    drawText("Multiple files, one quote list.", in: rect(254, 266, 360, 30), size: 22, weight: .medium)
    label("Export", at: CGPoint(x: 934, y: 302), width: 120)
    drawText("One quote per line in TXT.", in: rect(934, 266, 360, 30), size: 22, weight: .medium)
}

render("04-style-controls.png") {
    background()
    header("Match your menu bar.", "Choose font, size, color, and bold.")
    desktopMenuBar(y: 720, quote: "The details make the design.", quoteColor: NSColor(hex: 0x2b8178), bold: true)
    manageWindow(rect(214, 216, 760, 534), selected: 1, styleAccent: NSColor(hex: 0x2b8178))
    stylePopover(rect(888, 350, 252, 166))
    let samples: [(String, NSColor, NSFont)] = [
        ("System", NSColor(hex: 0x25231f), NSFont.systemFont(ofSize: 20)),
        ("Rounded", NSColor(hex: 0x2b8178), NSFont.systemFont(ofSize: 20, weight: .semibold)),
        ("Monospaced", NSColor(hex: 0x476f9f), NSFont.monospacedSystemFont(ofSize: 19, weight: .regular)),
        ("Serif", NSColor(hex: 0x7b5b95), NSFont(name: "Times New Roman", size: 21) ?? NSFont.systemFont(ofSize: 21))
    ]
    for (i, sample) in samples.enumerated() {
        let y = 594 - CGFloat(i) * 58
        rounded(rect(1202, y, 218, 42), radius: 10, fill: .white, stroke: NSColor(hex: 0xd9d5cc))
        drawText(sample.0, in: rect(1222, y + 11, 178, 20), size: 20, color: sample.1, font: sample.2)
    }
}

render("05-rotation.png") {
    background()
    header("Rotate on your schedule.", "Set hours and minutes for fresh quotes.")
    manageWindow(rect(238, 232, 808, 552), selected: 4, styleAccent: NSColor(hex: 0x9a6b24))
    shadow(alpha: 0.1, blur: 24, offset: CGSize(width: 0, height: -8)) {
        rounded(rect(1110, 408, 282, 202), radius: 18, fill: .white, stroke: NSColor(hex: 0xd9d5cc))
    }
    label("Interval", at: CGPoint(x: 1148, y: 548), width: 120)
    drawText("2 h 30 m", in: rect(1148, 486, 210, 54), size: 42, weight: .semibold, color: NSColor(hex: 0x9a6b24))
    drawText("The app advances when the configured interval has elapsed.", in: rect(1150, 440, 200, 46), size: 15, color: NSColor(hex: 0x6c6a63), lineHeight: 21)
}

render("06-next-quote-now.png") {
    background()
    header("Skip ahead instantly.", "Use Next Quote Now from the status menu.")
    desktopMenuBar(y: 724, quote: "Make each day your masterpiece.")
    menuPanel(rect(898, 486, 364, 198))
    shadow(alpha: 0.1, blur: 24, offset: CGSize(width: 0, height: -8)) {
        rounded(rect(278, 324, 548, 198), radius: 20, fill: .white, stroke: NSColor(hex: 0xd9d5cc))
    }
    label("Before", at: CGPoint(x: 326, y: 460), width: 120)
    drawText("Make each day your masterpiece.", in: rect(326, 424, 440, 28), size: 23, weight: .medium)
    label("After", at: CGPoint(x: 326, y: 384), width: 120)
    drawText("Simplicity is the ultimate sophistication.", in: rect(326, 348, 460, 28), size: 23, weight: .medium, color: NSColor(hex: 0x2b8178))
    line(from: CGPoint(x: 848, y: 430), to: CGPoint(x: 940, y: 578), color: NSColor(hex: 0xb9b2a5), width: 1.4)
}
