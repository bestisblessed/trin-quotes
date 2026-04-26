import AppKit
import Foundation

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Demo")
let iconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("MenuBarQuotes/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")

let canvas = CGSize(width: 1574, height: 1008)
let scale: CGFloat = 2

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
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = NSColor(hex: 0x172033),
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
    let f = font ?? NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: f,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSString(string: text).draw(in: rect, withAttributes: attrs)
}

func drawRounded(_ r: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func withShadow(color: NSColor = .black, alpha: CGFloat = 0.16, blur: CGFloat = 24, offset: CGSize = CGSize(width: 0, height: -8), _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color.withAlphaComponent(alpha)
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func drawGradientBackground(_ colors: [NSColor]) {
    NSGradient(colors: colors)?.draw(in: rect(0, 0, canvas.width, canvas.height), angle: 315)
    for i in 0..<7 {
        let x = CGFloat(i) * 250 - 60
        let y = CGFloat((i * 137) % 640) + 70
        let r = rect(x, y, 360, 170)
        NSColor.white.withAlphaComponent(i % 2 == 0 ? 0.07 : 0.045).setFill()
        NSBezierPath(roundedRect: r, xRadius: 85, yRadius: 85).fill()
    }
}

func drawHeader(_ title: String, _ subtitle: String, dark: Bool = false) {
    let color = dark ? NSColor.white : NSColor(hex: 0x172033)
    let sub = dark ? NSColor.white.withAlphaComponent(0.76) : NSColor(hex: 0x536176)
    drawText(title, in: rect(92, 72, 700, 88), size: 50, weight: .bold, color: color)
    drawText(subtitle, in: rect(94, 154, 760, 70), size: 24, color: sub, lineHeight: 32)
}

func drawWindow(_ r: CGRect, title: String, dark: Bool = false) {
    withShadow {
        drawRounded(r, radius: 18, fill: dark ? NSColor(hex: 0x151821) : NSColor(hex: 0xf8f9fb), stroke: NSColor.black.withAlphaComponent(0.09))
    }
    drawRounded(rect(r.minX, r.maxY - 54, r.width, 54), radius: 18, fill: dark ? NSColor(hex: 0x202431) : NSColor(hex: 0xf1f3f6))
    drawRounded(rect(r.minX, r.maxY - 65, r.width, 24), radius: 0, fill: dark ? NSColor(hex: 0x202431) : NSColor(hex: 0xf1f3f6))
    let dots: [(CGFloat, NSColor)] = [(0, NSColor(hex: 0xff5f57)), (24, NSColor(hex: 0xffbd2e)), (48, NSColor(hex: 0x28c840))]
    for (dx, c) in dots {
        drawRounded(rect(r.minX + 22 + dx, r.maxY - 34, 12, 12), radius: 6, fill: c)
    }
    drawText(title, in: rect(r.midX - 170, r.maxY - 40, 340, 24), size: 15, weight: .semibold, color: dark ? .white.withAlphaComponent(0.78) : NSColor(hex: 0x4b5567), align: .center)
}

func drawMenuBar(y: CGFloat, quote: String, color: NSColor = NSColor(hex: 0x132033), bold: Bool = false) {
    withShadow(alpha: 0.12, blur: 18, offset: CGSize(width: 0, height: -4)) {
        drawRounded(rect(84, y, 1406, 44), radius: 14, fill: NSColor.white.withAlphaComponent(0.86), stroke: NSColor.white.withAlphaComponent(0.7))
    }
    drawText("Finder", in: rect(118, y + 12, 80, 20), size: 15, weight: .semibold, color: NSColor(hex: 0x242938))
    drawText("File   Edit   View   Window   Help", in: rect(204, y + 12, 360, 20), size: 15, color: NSColor(hex: 0x394154))
    drawText(quote, in: rect(548, y + 10, 560, 24), size: 16, weight: bold ? .bold : .regular, color: color, align: .center)
    drawText("Wi-Fi   100%   Sun 9:41 AM", in: rect(1210, y + 12, 240, 20), size: 15, color: NSColor(hex: 0x394154), align: .right)
}

func drawButton(_ title: String, _ r: CGRect, primary: Bool = false, enabled: Bool = true) {
    let fill = primary ? NSColor(hex: 0x0a84ff) : NSColor(hex: 0xffffff)
    let stroke = primary ? NSColor(hex: 0x0a84ff) : NSColor(hex: 0xd4d9e2)
    drawRounded(r, radius: 7, fill: enabled ? fill : NSColor(hex: 0xf0f2f5), stroke: stroke)
    drawText(title, in: r.insetBy(dx: 8, dy: 7), size: 14, weight: .medium, color: primary ? .white : (enabled ? NSColor(hex: 0x273143) : NSColor(hex: 0x9aa3b2)), align: .center)
}

func drawManageWindow(_ r: CGRect, selected: Int = 1) {
    drawWindow(r, title: "Manage Quotes")
    let x = r.minX + 28
    let top = r.maxY - 90
    drawRounded(rect(x, top, r.width - 140, 34), radius: 7, fill: .white, stroke: NSColor(hex: 0xcfd6e1))
    drawText("Stay hungry, stay foolish.", in: rect(x + 12, top + 8, r.width - 170, 20), size: 14, color: NSColor(hex: 0x6a7381))
    drawButton("Add", rect(r.maxX - 92, top, 64, 34), primary: true)
    let table = rect(x, r.minY + 94, r.width - 56, 310)
    drawRounded(table, radius: 9, fill: .white, stroke: NSColor(hex: 0xd8dde6))
    let quotes = [
        "Great things are done by a series of small things brought together.",
        "Simplicity is the ultimate sophistication.",
        "The details are not the details. They make the design.",
        "Make each day your masterpiece.",
        "Energy and persistence conquer all things."
    ]
    for (idx, q) in quotes.enumerated() {
        let rowY = table.maxY - 52 - CGFloat(idx) * 52
        if idx == selected {
            drawRounded(rect(table.minX + 8, rowY + 8, table.width - 16, 36), radius: 7, fill: NSColor(hex: 0x0a84ff, alpha: 0.14))
        }
        if idx > 0 {
            NSColor(hex: 0xe8ebf0).setStroke()
            let p = NSBezierPath()
            p.move(to: CGPoint(x: table.minX + 14, y: rowY + 51))
            p.line(to: CGPoint(x: table.maxX - 14, y: rowY + 51))
            p.stroke()
        }
        drawText(q, in: rect(table.minX + 18, rowY + 17, table.width - 36, 22), size: 14, color: NSColor(hex: 0x243044))
    }
    let bottom = r.minY + 42
    var bx = x
    for title in ["Edit", "Delete", "Import", "Export", "Style...", "Done"] {
        drawButton(title, rect(bx, bottom, title == "Style..." ? 70 : 64, 32), primary: title == "Done")
        bx += title == "Style..." ? 80 : 74
    }
    drawText("Rotation", in: rect(r.maxX - 230, bottom + 7, 70, 20), size: 14, color: NSColor(hex: 0x4d5868), align: .right)
    drawRounded(rect(r.maxX - 150, bottom, 48, 32), radius: 6, fill: .white, stroke: NSColor(hex: 0xd2d8e2))
    drawText("2", in: rect(r.maxX - 142, bottom + 7, 30, 20), size: 14, color: NSColor(hex: 0x1f2937), align: .right)
    drawText("h", in: rect(r.maxX - 96, bottom + 7, 14, 20), size: 14, color: NSColor(hex: 0x4d5868))
    drawRounded(rect(r.maxX - 76, bottom, 48, 32), radius: 6, fill: .white, stroke: NSColor(hex: 0xd2d8e2))
    drawText("30", in: rect(r.maxX - 70, bottom + 7, 34, 20), size: 14, color: NSColor(hex: 0x1f2937), align: .right)
    drawText("m", in: rect(r.maxX - 22, bottom + 7, 18, 20), size: 14, color: NSColor(hex: 0x4d5868))
}

func drawPopover(_ r: CGRect) {
    withShadow(alpha: 0.18, blur: 24, offset: CGSize(width: 0, height: -8)) {
        drawRounded(r, radius: 14, fill: NSColor(hex: 0xffffff), stroke: NSColor(hex: 0xd7dce5))
    }
    let rows = [("Font", "Rounded"), ("Size", "Large"), ("Color", "Teal")]
    for (idx, row) in rows.enumerated() {
        let y = r.maxY - 42 - CGFloat(idx) * 42
        drawText(row.0, in: rect(r.minX + 18, y, 58, 20), size: 14, color: NSColor(hex: 0x5c6677), align: .right)
        drawRounded(rect(r.minX + 88, y - 5, r.width - 110, 30), radius: 7, fill: NSColor(hex: 0xf6f7f9), stroke: NSColor(hex: 0xdce1e8))
        drawText(row.1 + "  v", in: rect(r.minX + 102, y + 2, r.width - 136, 18), size: 14, color: NSColor(hex: 0x273143))
    }
    drawRounded(rect(r.minX + 92, r.minY + 18, 18, 18), radius: 5, fill: NSColor(hex: 0x0a84ff), stroke: NSColor(hex: 0x0a84ff))
    drawText("✓", in: rect(r.minX + 94, r.minY + 17, 14, 18), size: 13, weight: .bold, color: .white, align: .center)
    drawText("Bold", in: rect(r.minX + 120, r.minY + 17, 80, 20), size: 14, color: NSColor(hex: 0x273143))
}

func drawCallout(_ title: String, _ body: String, at r: CGRect, accent: NSColor = NSColor(hex: 0x0a84ff)) {
    withShadow(alpha: 0.12, blur: 18, offset: CGSize(width: 0, height: -5)) {
        drawRounded(r, radius: 16, fill: NSColor.white.withAlphaComponent(0.9), stroke: NSColor.white.withAlphaComponent(0.7))
    }
    drawRounded(rect(r.minX + 22, r.maxY - 48, 9, 28), radius: 4.5, fill: accent)
    drawText(title, in: rect(r.minX + 44, r.maxY - 50, r.width - 66, 24), size: 18, weight: .bold, color: NSColor(hex: 0x172033))
    drawText(body, in: rect(r.minX + 44, r.minY + 22, r.width - 66, r.height - 72), size: 15, color: NSColor(hex: 0x5b6678), lineHeight: 21)
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

render("1.png") {
    drawGradientBackground([NSColor(hex: 0xdfefff), NSColor(hex: 0xf7fbff), NSColor(hex: 0xf5e9df)])
    drawHeader("Quotes at a glance", "Keep a favorite line visible in the macOS menu bar while you work.")
    drawMenuBar(y: 846, quote: "Simplicity is the ultimate sophistication.", color: NSColor(hex: 0x172033), bold: false)
    withShadow(alpha: 0.18, blur: 28, offset: CGSize(width: 0, height: -10)) {
        drawRounded(rect(310, 332, 954, 278), radius: 26, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.82))
    }
    if let appIcon {
        appIcon.draw(in: rect(384, 410, 120, 120), from: .zero, operation: .sourceOver, fraction: 1)
    }
    drawText("Menu Bar Quotes", in: rect(542, 432, 520, 44), size: 34, weight: .bold, color: NSColor(hex: 0x172033))
    drawText("A tiny, focused companion for rotating quotes without opening an app window.", in: rect(544, 386, 540, 54), size: 20, color: NSColor(hex: 0x5d6778), lineHeight: 28)
    drawCallout("Always visible", "The current quote sits in the status area, trimmed cleanly when space is tight.", at: rect(980, 686, 396, 128))
}

render("2.png") {
    drawGradientBackground([NSColor(hex: 0xf6f8fb), NSColor(hex: 0xeaf3ee), NSColor(hex: 0xf8ede4)])
    drawHeader("Manage your quote library", "Add, edit, delete, import, and export from one compact Mac window.")
    drawManageWindow(rect(258, 244, 720, 560), selected: 2)
    drawCallout("Fast editing", "Select a row, refine the text, then save or remove it with standard controls.", at: rect(1030, 566, 374, 138), accent: NSColor(hex: 0x34c759))
    drawCallout("Portable library", "Import existing quote files and export your collection as plain text.", at: rect(1030, 392, 374, 138), accent: NSColor(hex: 0xff9f0a))
}

render("3.png") {
    drawGradientBackground([NSColor(hex: 0xf1f6ff), NSColor(hex: 0xffffff), NSColor(hex: 0xeaf7f2)])
    drawHeader("Import and export easily", "Bring in .txt, .csv, or .md files, then export your collection whenever you need it.")
    let cards: [(CGRect, String, String, [String], NSColor)] = [
        (rect(126, 348, 316, 310), "TXT", "focus.txt", ["Deep work beats busy work", "Make each day your masterpiece", "Small steps compound"], NSColor(hex: 0x0a84ff)),
        (rect(484, 348, 316, 310), "CSV", "quotes.csv", ["Stay hungry, stay foolish", "Energy and persistence", "Simplicity wins"], NSColor(hex: 0xff9f0a)),
        (rect(842, 348, 316, 310), "MD", "notes.md", ["## Favorites", "- The details make the design", "- Ship the useful thing"], NSColor(hex: 0xaf52de)),
        (rect(1200, 348, 316, 310), "TXT", "menu-bar-quotes.txt", ["Simplicity is the ultimate sophistication", "The details make the design", "Great things are done in steps"], NSColor(hex: 0x34c759))
    ]
    for (r, badge, title, lines, color) in cards {
        withShadow(alpha: 0.13, blur: 22, offset: CGSize(width: 0, height: -8)) {
            drawRounded(r, radius: 22, fill: .white, stroke: NSColor(hex: 0xdce2ea))
        }
        drawRounded(rect(r.minX + 28, r.maxY - 82, 66, 54), radius: 12, fill: color.withAlphaComponent(0.15), stroke: color.withAlphaComponent(0.35))
        drawText(badge, in: rect(r.minX + 40, r.maxY - 62, 42, 18), size: 14, weight: .bold, color: color, align: .center)
        drawText(title, in: rect(r.minX + 112, r.maxY - 66, 170, 28), size: 21, weight: .bold)
        for (i, line) in lines.enumerated() {
            let y = r.maxY - 132 - CGFloat(i) * 52
            drawRounded(rect(r.minX + 34, y, r.width - 68, 32), radius: 8, fill: NSColor(hex: 0xf4f6f9))
            drawText(line, in: rect(r.minX + 50, y + 8, r.width - 100, 18), size: 12, color: NSColor(hex: 0x5d6778))
        }
    }
    drawCallout("Multiple source files", "The import panel accepts plain text, comma-separated values, and Markdown files.", at: rect(210, 184, 500, 128), accent: NSColor(hex: 0x0a84ff))
    drawCallout("Simple export", "Export writes your quote library as menu-bar-quotes.txt, one quote per line.", at: rect(862, 184, 500, 128), accent: NSColor(hex: 0x34c759))
}

render("4.png") {
    drawGradientBackground([NSColor(hex: 0xeefaf8), NSColor(hex: 0xf8fbff), NSColor(hex: 0xf4edf9)])
    drawHeader("Customize the menu bar style", "Pick font, size, color, and bold styling for a status item that fits your desktop.")
    drawMenuBar(y: 820, quote: "The details make the design.", color: NSColor(hex: 0x159b8a), bold: true)
    drawManageWindow(rect(222, 252, 700, 520), selected: 1)
    drawPopover(rect(842, 340, 280, 186))
    let samples: [(String, NSColor, NSFont)] = [
        ("System", NSColor(hex: 0x172033), NSFont.systemFont(ofSize: 22)),
        ("Rounded", NSColor(hex: 0x159b8a), NSFont.systemFont(ofSize: 22, weight: .bold)),
        ("Monospaced", NSColor(hex: 0x0a84ff), NSFont.monospacedSystemFont(ofSize: 21, weight: .regular)),
        ("Serif", NSColor(hex: 0xaf52de), NSFont(name: "Times New Roman", size: 23) ?? NSFont.systemFont(ofSize: 23))
    ]
    var y: CGFloat = 594
    for (name, color, font) in samples {
        withShadow(alpha: 0.08, blur: 14, offset: CGSize(width: 0, height: -4)) {
            drawRounded(rect(1168, y, 238, 52), radius: 13, fill: .white, stroke: NSColor(hex: 0xdde3ec))
        }
        drawText(name, in: rect(1190, y + 14, 190, 26), size: 22, color: color, font: font)
        y -= 70
    }
    drawCallout("Live preview", "Style changes update the menu bar title immediately.", at: rect(1066, 698, 340, 112), accent: NSColor(hex: 0x159b8a))
}

render("5.png") {
    drawGradientBackground([NSColor(hex: 0xf9f3e8), NSColor(hex: 0xf8fbff), NSColor(hex: 0xeaf3ff)])
    drawHeader("Set the rotation pace", "Choose hours and minutes so your menu bar quote changes on your schedule.")
    drawManageWindow(rect(230, 270, 760, 540), selected: 4)
    withShadow(alpha: 0.15, blur: 24, offset: CGSize(width: 0, height: -7)) {
        drawRounded(rect(1054, 412, 340, 238), radius: 24, fill: .white, stroke: NSColor(hex: 0xdde3ec))
    }
    drawText("Rotation", in: rect(1096, 584, 250, 32), size: 28, weight: .bold)
    drawText("2 h 30 m", in: rect(1096, 518, 250, 54), size: 44, weight: .bold, color: NSColor(hex: 0xff9f0a))
    drawText("The app checks every minute and advances when the configured interval has elapsed.", in: rect(1098, 454, 240, 58), size: 16, color: NSColor(hex: 0x5d6778), lineHeight: 22)
    drawCallout("Stored with the library", "The configured interval is saved with your quotes and restored on launch.", at: rect(906, 164, 424, 126), accent: NSColor(hex: 0xff9f0a))
}

render("6.png") {
    drawGradientBackground([NSColor(hex: 0xf2f7ff), NSColor(hex: 0xffffff), NSColor(hex: 0xf7edf8)])
    drawHeader("Jump to the next quote", "Open the status menu and choose Next Quote Now for an immediate refresh.")
    drawMenuBar(y: 826, quote: "Make each day your masterpiece.", color: NSColor(hex: 0x172033), bold: false)

    let menu = rect(890, 564, 378, 210)
    withShadow(alpha: 0.22, blur: 30, offset: CGSize(width: 0, height: -10)) {
        drawRounded(menu, radius: 16, fill: .white, stroke: NSColor(hex: 0xd5dbe5))
    }
    drawText("Make each day your masterpiece.", in: rect(menu.minX + 24, menu.maxY - 48, menu.width - 48, 24), size: 15, color: NSColor(hex: 0x5b6678))
    NSColor(hex: 0xe5e9f0).setStroke()
    let separator = NSBezierPath()
    separator.move(to: CGPoint(x: menu.minX + 16, y: menu.maxY - 64))
    separator.line(to: CGPoint(x: menu.maxX - 16, y: menu.maxY - 64))
    separator.stroke()
    drawRounded(rect(menu.minX + 10, menu.maxY - 112, menu.width - 20, 36), radius: 8, fill: NSColor(hex: 0x0a84ff, alpha: 0.15))
    drawText("Next Quote Now", in: rect(menu.minX + 28, menu.maxY - 104, 220, 22), size: 16, weight: .semibold, color: NSColor(hex: 0x172033))
    drawText("Manage Quotes...", in: rect(menu.minX + 28, menu.maxY - 148, 220, 22), size: 16, color: NSColor(hex: 0x273143))
    drawText("Quit Menu Bar Quotes", in: rect(menu.minX + 28, menu.maxY - 188, 230, 22), size: 16, color: NSColor(hex: 0x273143))

    withShadow(alpha: 0.16, blur: 24, offset: CGSize(width: 0, height: -8)) {
        drawRounded(rect(250, 342, 610, 230), radius: 26, fill: .white, stroke: NSColor(hex: 0xdde3ec))
    }
    drawText("Before", in: rect(300, 500, 210, 28), size: 24, weight: .bold, color: NSColor(hex: 0x5b6678))
    drawText("Make each day your masterpiece.", in: rect(300, 452, 500, 34), size: 25, weight: .semibold, color: NSColor(hex: 0x172033))
    drawText("After", in: rect(300, 396, 210, 28), size: 24, weight: .bold, color: NSColor(hex: 0x0a84ff))
    drawText("Simplicity is the ultimate sophistication.", in: rect(300, 348, 520, 34), size: 25, weight: .semibold, color: NSColor(hex: 0x172033))
    drawCallout("No waiting", "ForceNextQuote advances the saved current index and resets the rotation timer.", at: rect(910, 300, 400, 132), accent: NSColor(hex: 0xaf52de))
}
