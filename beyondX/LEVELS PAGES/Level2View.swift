import SwiftUI
import PencilKit
import UIKit

// MARK: - Theme, Layout, Shadow

enum Level2Theme {
    static let cream = Color(red: 0.985, green: 0.975, blue: 0.93)
    static let highlight = Color(red: 0.80, green: 0.85, blue: 0.62)
    static let orange = Color(red: 0.85, green: 0.38, blue: 0.04)
    static let answerRed = Color(red: 0.68, green: 0.14, blue: 0.10)
    static let canvasBorder = Color.black.opacity(0.14)
}

enum Level2Layout {
    static let maxCanvas: CGFloat = 520
    static let panelHeight: CGFloat = 260
    static let handleOffset: CGFloat = 14
    static let maxAnswerLength = 20
    static let canvasSpace = "EditorCanvasSpace"
}

enum Level2Shadow {
    static let color: Color = Color.black.opacity(0.56)
    static let radius: CGFloat = 6
    static let x: CGFloat = 0
    static let y: CGFloat = 4
}

private extension View {
    /// The 56% shadow shared by the stop sign and every user shape.
    func level2Shadow() -> some View {
        shadow(color: Level2Shadow.color, radius: Level2Shadow.radius,
               x: Level2Shadow.x, y: Level2Shadow.y)
    }
}

// MARK: - Shape Kind

enum ShapeKind: String, CaseIterable, Identifiable {
    case circle, square, star, triangle
    case pentagon, parallelogram, semicircle, rectangle
    case tallRectangle, heart, diamond, oval
    case octagon

    var id: String { rawValue }

    /// Shapes offered in the picker. The octagon is only the original stop sign.
    static var pickerKinds: [ShapeKind] {
        allCases.filter { $0 != .octagon }
    }

    var title: String {
        switch self {
        case .circle: return "Circle"
        case .square: return "Square"
        case .star: return "Star"
        case .triangle: return "Triangle"
        case .pentagon: return "Pentagon"
        case .parallelogram: return "Parallelogram"
        case .semicircle: return "Semicircle"
        case .rectangle: return "Rectangle"
        case .tallRectangle: return "Tall rectangle"
        case .heart: return "Heart"
        case .diamond: return "Diamond"
        case .oval: return "Oval"
        case .octagon: return "Stop sign"
        }
    }

    /// Default size as a fraction of the canvas side.
    var defaultSize: CGSize {
        switch self {
        case .circle: return CGSize(width: 0.22, height: 0.22)
        case .square: return CGSize(width: 0.20, height: 0.20)
        case .star: return CGSize(width: 0.26, height: 0.26)
        case .triangle: return CGSize(width: 0.24, height: 0.22)
        case .pentagon: return CGSize(width: 0.24, height: 0.24)
        case .parallelogram: return CGSize(width: 0.30, height: 0.16)
        case .semicircle: return CGSize(width: 0.30, height: 0.15)
        case .rectangle: return CGSize(width: 0.30, height: 0.18)
        case .tallRectangle: return CGSize(width: 0.14, height: 0.26)
        case .heart: return CGSize(width: 0.26, height: 0.24)
        case .diamond: return CGSize(width: 0.24, height: 0.24)
        case .oval: return CGSize(width: 0.30, height: 0.20)
        case .octagon: return CGSize(width: 0.53, height: 0.53)
        }
    }
}

// MARK: - Colors

enum PaletteColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, blue, purple, pink, black, white

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.68, green: 0.14, blue: 0.10)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.13)
        case .yellow: return Color(red: 0.97, green: 0.80, blue: 0.20)
        case .green: return Color(red: 0.27, green: 0.52, blue: 0.17)
        case .blue: return Color(red: 0.20, green: 0.45, blue: 0.85)
        case .purple: return Color(red: 0.55, green: 0.33, blue: 0.75)
        case .pink: return Color(red: 0.95, green: 0.50, blue: 0.70)
        case .black: return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .white: return Color.white
        }
    }
}

// MARK: - Canvas Item (user-created shape)

/// One independent user shape. Position and size are normalized to the canvas side.
/// `order` is its place in the chronological stack (shapes and stroke layers share one counter).
struct CanvasItem: Identifiable, Equatable {
    let id: UUID
    var kind: ShapeKind
    var palette: PaletteColor
    var center: CGPoint
    var scale: CGFloat
    var rotation: CGFloat // radians
    var order: Int

    init(id: UUID = UUID(),
         kind: ShapeKind,
         palette: PaletteColor,
         center: CGPoint,
         scale: CGFloat = 1,
         rotation: CGFloat = 0,
         order: Int = 0) {
        self.id = id
        self.kind = kind
        self.palette = palette
        self.center = center
        self.scale = scale
        self.rotation = rotation
        self.order = order
    }

    var size: CGSize {
        let base: CGSize = kind.defaultSize
        return CGSize(width: base.width * scale, height: base.height * scale)
    }

    /// Half extents of the axis-aligned box that contains the rotated shape.
    var halfExtents: CGSize {
        let c: CGFloat = abs(cos(rotation))
        let s: CGFloat = abs(sin(rotation))
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        return CGSize(width: (w * c + h * s) / 2, height: (w * s + h * c) / 2)
    }

    var minScale: CGFloat {
        let smallest: CGFloat = min(kind.defaultSize.width, kind.defaultSize.height)
        return 0.08 / smallest
    }

    /// Largest scale that still fits inside the canvas at the current rotation.
    var maxScale: CGFloat {
        let c: CGFloat = abs(cos(rotation))
        let s: CGFloat = abs(sin(rotation))
        let w: CGFloat = kind.defaultSize.width
        let h: CGFloat = kind.defaultSize.height
        let boundsW: CGFloat = max(w * c + h * s, 0.001)
        let boundsH: CGFloat = max(w * s + h * c, 0.001)
        let fit: CGFloat = min(1 / boundsW, 1 / boundsH)
        return min(3, fit)
    }
}

// MARK: - Stroke Layers & Chronological Stack

/// A group of pen strokes drawn between two shape insertions.
struct StrokeLayer: Identifiable {
    let id = UUID()
    var order: Int
    var drawing: PKDrawing
    /// Changes whenever the drawing changes, so the cached image knows when to re-render.
    var version = UUID()
}

/// One entry of the back-to-front stack: either a shape or a sealed group of strokes.
enum CanvasLayer: Identifiable {
    case shape(CanvasItem)
    case strokes(StrokeLayer)

    var id: UUID {
        switch self {
        case .shape(let item): return item.id
        case .strokes(let layer): return layer.id
        }
    }

    var order: Int {
        switch self {
        case .shape(let item): return item.order
        case .strokes(let layer): return layer.order
        }
    }
}

// MARK: - History Snapshot

/// Everything the user can change. The original stop sign is NOT part of this.
struct EditorSnapshot {
    var items: [CanvasItem]
    var layers: [StrokeLayer]
}

// MARK: - Shape Paths

struct KindShape: Shape {
    let kind: ShapeKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .circle, .oval:
            return Path(ellipseIn: rect)
        case .square, .rectangle, .tallRectangle:
            return Path(rect)
        case .star:
            return starPath(in: rect)
        case .triangle:
            return trianglePath(in: rect)
        case .pentagon:
            return regularPolygon(sides: 5, in: rect)
        case .parallelogram:
            return parallelogramPath(in: rect)
        case .semicircle:
            return semicirclePath(in: rect)
        case .heart:
            return heartPath(in: rect)
        case .diamond:
            return diamondPath(in: rect)
        case .octagon:
            return octagonPath(in: rect)
        }
    }

    private func polygon(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    private func trianglePath(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.maxY)
        return polygon([top, right, left])
    }

    private func diamondPath(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.midY)
        return polygon([top, right, bottom, left])
    }

    private func parallelogramPath(in rect: CGRect) -> Path {
        let skew: CGFloat = rect.width * 0.28
        let p1 = CGPoint(x: rect.minX + skew, y: rect.minY)
        let p2 = CGPoint(x: rect.maxX, y: rect.minY)
        let p3 = CGPoint(x: rect.maxX - skew, y: rect.maxY)
        let p4 = CGPoint(x: rect.minX, y: rect.maxY)
        return polygon([p1, p2, p3, p4])
    }

    private func octagonPath(in rect: CGRect) -> Path {
        let cut: CGFloat = min(rect.width, rect.height) * 0.2929
        let p1 = CGPoint(x: rect.minX + cut, y: rect.minY)
        let p2 = CGPoint(x: rect.maxX - cut, y: rect.minY)
        let p3 = CGPoint(x: rect.maxX, y: rect.minY + cut)
        let p4 = CGPoint(x: rect.maxX, y: rect.maxY - cut)
        let p5 = CGPoint(x: rect.maxX - cut, y: rect.maxY)
        let p6 = CGPoint(x: rect.minX + cut, y: rect.maxY)
        let p7 = CGPoint(x: rect.minX, y: rect.maxY - cut)
        let p8 = CGPoint(x: rect.minX, y: rect.minY + cut)
        return polygon([p1, p2, p3, p4, p5, p6, p7, p8])
    }

    private func regularPolygon(sides: Int, in rect: CGRect) -> Path {
        let radius: CGFloat = min(rect.width, rect.height) / 2
        let start: CGFloat = -(CGFloat.pi / 2)
        let step: CGFloat = 2 * CGFloat.pi / CGFloat(sides)
        var points: [CGPoint] = []
        for i in 0..<sides {
            let angle: CGFloat = start + CGFloat(i) * step
            let x: CGFloat = rect.midX + radius * cos(angle)
            let y: CGFloat = rect.midY + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }

    private func starPath(in rect: CGRect) -> Path {
        let outer: CGFloat = min(rect.width, rect.height) / 2
        let inner: CGFloat = outer * 0.42
        let start: CGFloat = -(CGFloat.pi / 2)
        let step: CGFloat = CGFloat.pi / 5
        var points: [CGPoint] = []
        for i in 0..<10 {
            let radius: CGFloat = (i % 2 == 0) ? outer : inner
            let angle: CGFloat = start + CGFloat(i) * step
            let x: CGFloat = rect.midX + radius * cos(angle)
            let y: CGFloat = rect.midY + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }

    /// Flat edge on top, curve below.
    private func semicirclePath(in rect: CGRect) -> Path {
        let steps = 48
        let halfWidth: CGFloat = rect.width / 2
        var points: [CGPoint] = []
        for i in 0...steps {
            let t: CGFloat = CGFloat.pi * CGFloat(i) / CGFloat(steps)
            let x: CGFloat = rect.midX + halfWidth * cos(t)
            let y: CGFloat = rect.minY + rect.height * sin(t)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }

    private func heartPath(in rect: CGRect) -> Path {
        let w: CGFloat = rect.width
        let h: CGFloat = rect.height
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let leftSide = CGPoint(x: rect.minX, y: rect.minY + h * 0.32)
        let dip = CGPoint(x: rect.midX, y: rect.minY + h * 0.28)
        let rightSide = CGPoint(x: rect.maxX, y: rect.minY + h * 0.32)

        let leftLow = CGPoint(x: rect.midX - w * 0.2, y: rect.maxY - h * 0.2)
        let leftMid = CGPoint(x: rect.minX, y: rect.midY + h * 0.1)
        let leftTop = CGPoint(x: rect.minX, y: rect.minY - h * 0.05)
        let leftDip = CGPoint(x: rect.midX - w * 0.08, y: rect.minY - h * 0.02)
        let rightDip = CGPoint(x: rect.midX + w * 0.08, y: rect.minY - h * 0.02)
        let rightTop = CGPoint(x: rect.maxX, y: rect.minY - h * 0.05)
        let rightMid = CGPoint(x: rect.maxX, y: rect.midY + h * 0.1)
        let rightLow = CGPoint(x: rect.midX + w * 0.2, y: rect.maxY - h * 0.2)

        var path = Path()
        path.move(to: bottom)
        path.addCurve(to: leftSide, control1: leftLow, control2: leftMid)
        path.addCurve(to: dip, control1: leftTop, control2: leftDip)
        path.addCurve(to: rightSide, control1: rightDip, control2: rightTop)
        path.addCurve(to: bottom, control1: rightMid, control2: rightLow)
        path.closeSubpath()
        return path
    }
}

// MARK: - Editor Model (user shapes + stroke layers + history)

/// Owns everything the user can edit. The original stop sign is deliberately not stored here.
@Observable
final class EditorModel {
    var items: [CanvasItem] = []
    var layers: [StrokeLayer] = []
    var drawingRevision = 0
    var selectedID: UUID?
    var paletteID: UUID?

    /// Transient copy of the shape being dragged, resized or rotated. Committed once per gesture.
    private(set) var live: CanvasItem?
    private var liveBase: CanvasItem?

    private(set) var undoStack: [EditorSnapshot] = []
    private(set) var redoStack: [EditorSnapshot] = []

    /// Shared counter that orders shapes and stroke layers chronologically.
    private var nextOrder = 1

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasDrawing: Bool { layers.contains { !$0.drawing.strokes.isEmpty } }

    /// True when the canvas holds any user-made content. Drives the bottom button and the trash button.
    var hasEdits: Bool { !items.isEmpty || hasDrawing }

    private var current: EditorSnapshot {
        EditorSnapshot(items: items, layers: layers)
    }

    // MARK: Chronological stack

    private var topShapeOrder: Int {
        items.map { $0.order }.max() ?? 0
    }

    /// The newest stroke layer, if it is newer than every shape. This one is edited live by PencilKit.
    private var activeIndex: Int? {
        guard let last = layers.indices.last, layers[last].order > topShapeOrder else { return nil }
        return last
    }

    /// Drawing shown in the live `PKCanvasView`.
    var activeDrawing: PKDrawing {
        guard let index = activeIndex else { return PKDrawing() }
        return layers[index].drawing
    }

    /// Shapes and sealed stroke layers, back to front. The live canvas is drawn above all of these.
    var stack: [CanvasLayer] {
        let sealedCount: Int = activeIndex ?? layers.count
        var result: [CanvasLayer] = items.map { CanvasLayer.shape($0) }
        for layer in layers.prefix(sealedCount) {
            result.append(CanvasLayer.strokes(layer))
        }
        return result.sorted { $0.order < $1.order }
    }

    // MARK: History

    private func commit(_ change: () -> Void) {
        undoStack.append(current)
        if undoStack.count > 100 { undoStack.removeFirst() }
        redoStack.removeAll()
        change()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(current)
        restore(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(current)
        restore(next)
    }

    private func restore(_ snapshot: EditorSnapshot) {
        live = nil
        liveBase = nil
        items = snapshot.items
        layers = snapshot.layers
        drawingRevision += 1
        if let id = selectedID, !items.contains(where: { $0.id == id }) { selectedID = nil }
        if let id = paletteID, !items.contains(where: { $0.id == id }) { paletteID = nil }
    }

    // MARK: Drawing

    /// Called by PencilKit after every stroke. Updates the newest layer or starts a new one.
    func drawingChanged(to newDrawing: PKDrawing) {
        let old: Data = activeDrawing.dataRepresentation()
        let new: Data = newDrawing.dataRepresentation()
        guard old != new else { return }
        commit {
            if let index = activeIndex {
                layers[index].drawing = newDrawing
                layers[index].version = UUID()
            } else {
                layers.append(StrokeLayer(order: nextOrder, drawing: newDrawing))
                nextOrder += 1
            }
        }
    }

    /// Removes every user shape and stroke as one undoable step. The stop sign is unaffected.
    func clearAll() {
        guard hasEdits else { return }
        commit {
            items = []
            layers = []
            selectedID = nil
            paletteID = nil
        }
        live = nil
        liveBase = nil
        drawingRevision += 1
    }

    // MARK: Geometry

    /// Clamps scale and position so the whole rotated shape stays inside the canvas.
    static func normalized(_ item: CanvasItem) -> CanvasItem {
        var result = item
        let upper: CGFloat = max(result.maxScale, result.minScale)
        result.scale = min(max(result.scale, result.minScale), upper)
        let half: CGSize = result.halfExtents
        let hx: CGFloat = min(half.width, 0.5)
        let hy: CGFloat = min(half.height, 0.5)
        let x: CGFloat = min(max(result.center.x, hx), 1 - hx)
        let y: CGFloat = min(max(result.center.y, hy), 1 - hy)
        result.center = CGPoint(x: x, y: y)
        return result
    }

    // MARK: Selection

    func select(_ id: UUID?) {
        if selectedID != id { selectedID = id }
        paletteID = nil
    }

    // MARK: Shapes

    func addItem(kind: ShapeKind, at center: CGPoint?) {
        let stagger: CGFloat = CGFloat(items.count % 5) - 2
        let fallback = CGPoint(x: 0.5 + stagger * 0.04, y: 0.5 + stagger * 0.04)
        let proposed: CGPoint = center ?? fallback
        let raw = CanvasItem(kind: kind, palette: .white, center: proposed, order: nextOrder)
        nextOrder += 1
        let item: CanvasItem = Self.normalized(raw)
        commit {
            items.append(item)
            selectedID = item.id
            paletteID = nil
        }
        // The newest stroke layer is now below this shape, so the live canvas starts empty.
        drawingRevision += 1
    }

    /// One-shot change (used by accessibility actions and recoloring).
    func transform(_ id: UUID, _ change: (inout CanvasItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var updated: CanvasItem = items[index]
        change(&updated)
        updated = Self.normalized(updated)
        guard updated != items[index] else { return }
        commit { items[index] = updated }
    }

    func rotate(_ id: UUID, by delta: CGFloat) {
        transform(id) { item in item.rotation += delta }
    }

    func resize(_ id: UUID, by factor: CGFloat) {
        transform(id) { item in item.scale *= factor }
    }

    func setColor(_ id: UUID, to palette: PaletteColor) {
        transform(id) { item in item.palette = palette }
    }

    func deleteItem(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        commit {
            items.removeAll { $0.id == id }
            if selectedID == id { selectedID = nil }
            if paletteID == id { paletteID = nil }
        }
        // Removing the newest shape can make the newest stroke layer live again.
        drawingRevision += 1
    }

    // MARK: Live gestures (one undo step per gesture)

    func displayed(_ item: CanvasItem) -> CanvasItem {
        if let live, live.id == item.id { return live }
        return item
    }

    @discardableResult
    func beginLive(_ id: UUID) -> CanvasItem? {
        if let base = liveBase, base.id == id { return base }
        if liveBase != nil { commitLive() }
        guard let item = items.first(where: { $0.id == id }) else { return nil }
        liveBase = item
        live = item
        return item
    }

    func updateLive(_ change: (inout CanvasItem) -> Void) {
        guard var updated = live else { return }
        change(&updated)
        live = Self.normalized(updated)
    }

    func commitLive() {
        let finished: CanvasItem? = live
        let base: CanvasItem? = liveBase
        live = nil
        liveBase = nil
        guard let finished, let base, finished != base else { return }
        guard let index = items.firstIndex(where: { $0.id == finished.id }) else { return }
        commit { items[index] = finished }
    }
}

// MARK: - PencilKit Bridge (Apple Notes / Markup tool picker)

struct DrawingCanvas: UIViewRepresentable {
    let model: EditorModel
    let revision: Int
    let isEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.bounces = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.showsVerticalScrollIndicator = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.clipsToBounds = true
        canvas.overrideUserInterfaceStyle = .light
        canvas.delegate = context.coordinator
        canvas.isUserInteractionEnabled = isEnabled
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)

        context.coordinator.toolPicker.addObserver(canvas)

        context.coordinator.isApplying = true
        canvas.drawing = model.activeDrawing
        context.coordinator.isApplying = false
        context.coordinator.appliedRevision = revision
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEnabled
        if context.coordinator.appliedRevision != revision {
            context.coordinator.isApplying = true
            canvas.drawing = model.activeDrawing
            context.coordinator.isApplying = false
            context.coordinator.appliedRevision = revision
        }
        context.coordinator.setPickerVisible(isEnabled, for: canvas)
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker.setVisible(false, forFirstResponder: canvas)
        coordinator.toolPicker.removeObserver(canvas)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let model: EditorModel
        let toolPicker = PKToolPicker()
        var appliedRevision = 0
        var isApplying = false
        private var pickerVisible = false

        init(model: EditorModel) {
            self.model = model
        }

        func setPickerVisible(_ visible: Bool, for canvas: PKCanvasView) {
            guard visible != pickerVisible else { return }
            pickerVisible = visible
            DispatchQueue.main.async { [toolPicker] in
                toolPicker.setVisible(visible, forFirstResponder: canvas)
                if visible {
                    canvas.becomeFirstResponder()
                } else {
                    canvas.resignFirstResponder()
                }
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // The model owns history; keep PencilKit's own undo manager out of the way.
            canvasView.undoManager?.removeAllActions()
            guard !isApplying else { return }
            model.drawingChanged(to: canvasView.drawing)
        }
    }
}

// MARK: - Sealed Strokes (read-only image of an older stroke layer)

struct StrokeImageView: View, Equatable {
    let layer: StrokeLayer
    let side: CGFloat

    @Environment(\.displayScale) private var displayScale

    static func == (lhs: StrokeImageView, rhs: StrokeImageView) -> Bool {
        lhs.layer.id == rhs.layer.id && lhs.layer.version == rhs.layer.version && lhs.side == rhs.side
    }

    var body: some View {
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        let image: UIImage = layer.drawing.image(from: bounds, scale: displayScale)
        return Image(uiImage: image)
            .resizable()
            .frame(width: side, height: side)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Original Stop Sign

/// The activity's starting element. It is not an item, so it cannot be selected, moved or cleared.
struct StopSignView: View {
    let side: CGFloat

    var body: some View {
        let size: CGSize = ShapeKind.octagon.defaultSize
        KindShape(kind: .octagon)
            .fill(PaletteColor.red.color)
            .frame(width: size.width * side, height: size.height * side)
            .level2Shadow()
            .position(x: side / 2, y: side / 2)
            .allowsHitTesting(false)
            .accessibilityLabel("Red stop sign")
    }
}

// MARK: - Canvas Card

struct CanvasCard: View {
    let model: EditorModel
    let side: CGFloat
    let isDrawing: Bool
    let onDropShape: (ShapeKind, CGPoint) -> Void

    @State private var isDropTargeted = false

    private var selectedItem: CanvasItem? {
        guard let id = model.selectedID,
              let item = model.items.first(where: { $0.id == id }) else { return nil }
        return model.displayed(item)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            card
            handlesLayer
        }
        .frame(width: side, height: side)
        .coordinateSpace(.named(Level2Layout.canvasSpace))
    }

    @ViewBuilder
    private var handlesLayer: some View {
        if let selectedItem, !isDrawing {
            SelectionOverlay(model: model, item: selectedItem, side: side)
        }
    }

    private var card: some View {
        content
            .frame(width: side, height: side)
            .background(Level2Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { border }
            .dropDestination(for: String.self) { strings, location in
                handleDrop(strings: strings, location: location)
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
    }

    /// Back to front: background, stop sign, then shapes and sealed strokes in the order they were
    /// made, and finally the live PencilKit canvas for the newest strokes.
    private var content: some View {
        ZStack(alignment: .topLeading) {
            backgroundTapLayer
            StopSignView(side: side)
            ForEach(model.stack) { layer in
                layerView(layer)
            }
            DrawingCanvas(model: model,
                          revision: model.drawingRevision,
                          isEnabled: isDrawing)
                .allowsHitTesting(isDrawing)
        }
    }

    @ViewBuilder
    private func layerView(_ layer: CanvasLayer) -> some View {
        switch layer {
        case .shape(let item):
            ShapeItemView(item: model.displayed(item), side: side, model: model)
        case .strokes(let strokes):
            StrokeImageView(layer: strokes, side: side).equatable()
        }
    }

    private var backgroundTapLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { model.select(nil) }
    }

    private var border: some View {
        let color: Color = isDropTargeted ? Level2Theme.orange : Level2Theme.canvasBorder
        let width: CGFloat = isDropTargeted ? 2 : 1
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(color, lineWidth: width)
            .allowsHitTesting(false)
    }

    private func handleDrop(strings: [String], location: CGPoint) -> Bool {
        guard side > 0, let raw = strings.first, raw.hasPrefix("shape:") else { return false }
        let name = String(raw.dropFirst(6))
        guard let kind = ShapeKind(rawValue: name), kind != .octagon else { return false }
        let normalized = CGPoint(x: location.x / side, y: location.y / side)
        onDropShape(kind, normalized)
        return true
    }
}

// MARK: - Shape View

struct ShapeItemView: View {
    let item: CanvasItem
    let side: CGFloat
    let model: EditorModel

    private var isSelected: Bool { model.selectedID == item.id }

    private var paletteBinding: Binding<Bool> {
        Binding(
            get: { model.paletteID == item.id },
            set: { isPresented in
                if !isPresented && model.paletteID == item.id { model.paletteID = nil }
            }
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Level2Layout.canvasSpace))
            .onChanged { value in handleDragChanged(value) }
            .onEnded { _ in model.commitLive() }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        guard side > 0, let base = model.beginLive(item.id) else { return }
        if model.selectedID != item.id { model.selectedID = item.id }
        if model.paletteID != nil { model.paletteID = nil }
        let dx: CGFloat = value.translation.width / side
        let dy: CGFloat = value.translation.height / side
        model.updateLive { live in
            live.center = CGPoint(x: base.center.x + dx, y: base.center.y + dy)
        }
    }

    private func tapped() {
        if isSelected {
            model.paletteID = (model.paletteID == item.id) ? nil : item.id
        } else {
            model.select(item.id)
        }
    }

    private var shapeBody: some View {
        let width: CGFloat = item.size.width * side
        let height: CGFloat = item.size.height * side
        let outlineOpacity: Double = (item.palette == .white) ? 0.15 : 0
        return KindShape(kind: item.kind)
            .fill(item.palette.color)
            .overlay {
                KindShape(kind: item.kind)
                    .stroke(Color.black.opacity(outlineOpacity), lineWidth: 1)
            }
            .frame(width: width, height: height)
            .contentShape(KindShape(kind: item.kind))
            .rotationEffect(Angle(radians: Double(item.rotation)))
            .level2Shadow()
    }

    var body: some View {
        let position = CGPoint(x: item.center.x * side, y: item.center.y * side)
        return shapeBody
            .gesture(dragGesture)
            .onTapGesture { tapped() }
            .popover(isPresented: paletteBinding) { palettePopover }
            .position(position)
            .modifier(ShapeAccessibility(item: item, model: model, isSelected: isSelected))
    }

    private var palettePopover: some View {
        ColorPalettePopover(
            selected: item.palette,
            onPick: { chosen in
                model.setColor(item.id, to: chosen)
                model.paletteID = nil
            },
            onDelete: { model.deleteItem(item.id) }
        )
        .presentationCompactAdaptation(.popover)
    }
}

/// Accessibility for a shape. Each action is a single call into the model.
struct ShapeAccessibility: ViewModifier {
    let item: CanvasItem
    let model: EditorModel
    let isSelected: Bool

    private let rotationStep: CGFloat = .pi / 12
    private let resizeFactor: CGFloat = 1.15

    private var traits: AccessibilityTraits {
        isSelected ? [.isButton, .isSelected] : [.isButton]
    }

    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            .accessibilityLabel("\(item.palette.name) \(item.kind.title)")
            .accessibilityHint("Double tap to select. Double tap again to change its color.")
            .accessibilityAddTraits(traits)
            .accessibilityAction(named: "Change Color") { changeColor() }
            .accessibilityAction(named: "Rotate 15 degrees") { model.rotate(item.id, by: rotationStep) }
            .accessibilityAction(named: "Make Larger") { model.resize(item.id, by: resizeFactor) }
            .accessibilityAction(named: "Make Smaller") { model.resize(item.id, by: 1 / resizeFactor) }
            .accessibilityAction(named: "Delete Shape") { model.deleteItem(item.id) }
    }

    private func changeColor() {
        model.select(item.id)
        model.paletteID = item.id
    }
}

// MARK: - Selection Handles (resize + rotate)

struct SelectionOverlay: View {
    let model: EditorModel
    let item: CanvasItem
    let side: CGFloat

    private var center: CGPoint {
        CGPoint(x: item.center.x * side, y: item.center.y * side)
    }
    private var width: CGFloat { item.size.width * side }
    private var height: CGFloat { item.size.height * side }

    /// Converts an offset from the shape center (in the shape's rotated frame) to canvas space.
    private func point(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        let c: CGFloat = cos(item.rotation)
        let s: CGFloat = sin(item.rotation)
        return CGPoint(x: center.x + dx * c - dy * s, y: center.y + dx * s + dy * c)
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Level2Layout.canvasSpace))
            .onChanged { value in resizeChanged(value) }
            .onEnded { _ in model.commitLive() }
    }

    private var rotateGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Level2Layout.canvasSpace))
            .onChanged { value in rotateChanged(value) }
            .onEnded { _ in model.commitLive() }
    }

    private func resizeChanged(_ value: DragGesture.Value) {
        guard side > 0, let base = model.beginLive(item.id) else { return }
        let c = CGPoint(x: base.center.x * side, y: base.center.y * side)
        let baseWidth: CGFloat = base.size.width * side
        let baseHeight: CGFloat = base.size.height * side
        let diagonal: CGFloat = hypot(baseWidth, baseHeight) / 2
        let cornerDistance: CGFloat = max(diagonal, 1)
        let startDX: CGFloat = value.startLocation.x - c.x
        let startDY: CGFloat = value.startLocation.y - c.y
        let nowDX: CGFloat = value.location.x - c.x
        let nowDY: CGFloat = value.location.y - c.y
        let startDistance: CGFloat = hypot(startDX, startDY)
        let distance: CGFloat = hypot(nowDX, nowDY)
        let newCorner: CGFloat = cornerDistance + (distance - startDistance)
        let factor: CGFloat = newCorner / cornerDistance
        model.updateLive { live in
            live.scale = base.scale * factor
        }
    }

    private func rotateChanged(_ value: DragGesture.Value) {
        guard side > 0, let base = model.beginLive(item.id) else { return }
        let c = CGPoint(x: base.center.x * side, y: base.center.y * side)
        let startAngle: CGFloat = atan2(value.startLocation.y - c.y, value.startLocation.x - c.x)
        let angle: CGFloat = atan2(value.location.y - c.y, value.location.x - c.x)
        var rotation: CGFloat = base.rotation + (angle - startAngle)
        let step: CGFloat = CGFloat.pi / 4
        let nearest: CGFloat = (rotation / step).rounded() * step
        if abs(rotation - nearest) < 0.05 { rotation = nearest }
        model.updateLive { live in
            live.rotation = rotation
        }
    }

    private func handle(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Level2Theme.orange)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Color.white))
            .overlay(Circle().stroke(Level2Theme.orange, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    private var dashedBox: some View {
        Rectangle()
            .stroke(Level2Theme.orange.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            .frame(width: width, height: height)
            .rotationEffect(Angle(radians: Double(item.rotation)))
            .position(center)
            .allowsHitTesting(false)
    }

    private var rotateHandle: some View {
        let offset: CGFloat = Level2Layout.handleOffset
        let position: CGPoint = point(-(width / 2 + offset), -(height / 2 + offset))
        return handle(symbol: "arrow.triangle.2.circlepath")
            .position(position)
            .gesture(rotateGesture)
            .accessibilityLabel("Rotate shape")
            .accessibilityHint("Swipe up or down to rotate.")
            .accessibilityAdjustableAction { direction in
                let step: CGFloat = CGFloat.pi / 12
                model.rotate(item.id, by: direction == .increment ? step : -step)
            }
    }

    private var resizeHandle: some View {
        let offset: CGFloat = Level2Layout.handleOffset
        let position: CGPoint = point(width / 2 + offset, height / 2 + offset)
        return handle(symbol: "arrow.up.left.and.arrow.down.right")
            .position(position)
            .gesture(resizeGesture)
            .accessibilityLabel("Resize shape")
            .accessibilityHint("Swipe up or down to resize.")
            .accessibilityAdjustableAction { direction in
                let factor: CGFloat = 1.15
                model.resize(item.id, by: direction == .increment ? factor : 1 / factor)
            }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            dashedBox
            rotateHandle
            resizeHandle
        }
        .frame(width: side, height: side, alignment: .topLeading)
    }
}

// MARK: - Color Palette Popover

struct ColorPalettePopover: View {
    let selected: PaletteColor
    let onPick: (PaletteColor) -> Void
    let onDelete: () -> Void

    private let swatchSize: CGFloat = 44
    private let gap: CGFloat = 6

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(swatchSize), spacing: gap), count: 5)
    }

    private var popoverWidth: CGFloat {
        let swatches: CGFloat = swatchSize * 5
        let gaps: CGFloat = gap * 4
        return swatches + gaps + 28
    }

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: gap) {
                ForEach(PaletteColor.allCases) { palette in
                    swatch(palette)
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete Shape", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(14)
        .frame(width: popoverWidth)
    }

    private func swatch(_ palette: PaletteColor) -> some View {
        let isSelected: Bool = (palette == selected)
        return Button {
            onPick(palette)
        } label: {
            ZStack {
                Circle()
                    .fill(palette.color)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                if isSelected {
                    Circle()
                        .stroke(Level2Theme.orange, lineWidth: 3)
                        .frame(width: 40, height: 40)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(palette.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Toolbar

struct EditorToolbar: View {
    let isDrawing: Bool
    let isShowingShapes: Bool
    let canUndo: Bool
    let canRedo: Bool
    let canClear: Bool
    let onPen: () -> Void
    let onShapes: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack {
            toolsPill
            Spacer(minLength: 12)
            historyPill
        }
    }

    private var toolsPill: some View {
        let penSymbol: String = isDrawing ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
        let penHint: String = isDrawing
            ? "Drawing is on. Double tap to switch back to moving shapes."
            : "Double tap to draw on the canvas."
        return pill {
            toolButton(symbol: penSymbol, label: "Pen", hint: penHint,
                       isActive: isDrawing, action: onPen)
            toolButton(symbol: "square.on.circle", label: "Shapes",
                       hint: "Opens the shape picker.",
                       isActive: isShowingShapes, action: onShapes)
        }
    }

    private var historyPill: some View {
        pill {
            toolButton(symbol: "arrow.uturn.backward", label: "Undo",
                       isEnabled: canUndo, action: onUndo)
            toolButton(symbol: "arrow.uturn.forward", label: "Redo",
                       isEnabled: canRedo, action: onRedo)
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 1, height: 20)
                .accessibilityHidden(true)
            toolButton(symbol: "trash", label: "Clear canvas",
                       hint: "Removes your shapes and drawing after confirmation. The stop sign stays.",
                       tint: .red, isEnabled: canClear, action: onClear)
        }
    }

    private func pill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) { content() }
            .padding(.horizontal, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private func toolButton(symbol: String,
                            label: String,
                            hint: String = "",
                            tint: Color = .black,
                            isActive: Bool = false,
                            isEnabled: Bool = true,
                            action: @escaping () -> Void) -> some View {
        let iconColor: Color = isActive ? Level2Theme.orange : tint
        let opacity: Double = isEnabled ? 1 : 0.35
        return Button(action: action) {
            ZStack {
                if isActive {
                    Circle().fill(Level2Theme.orange.opacity(0.18)).frame(width: 38, height: 38)
                }
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(opacity)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Shapes Panel (bottom panel in the same hierarchy as the toolbar)

struct ShapesPanel: View {
    /// Kind of the shape currently selected on the canvas, if any. Shown with an orange ring.
    let selectedKind: ShapeKind?
    let onSelect: (ShapeKind) -> Void
    let onDismiss: () -> Void

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            handle
            ScrollView {
                grid
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Level2Layout.panelHeight, alignment: .top)
        .background { panelBackground }
    }

    private var panelBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 28,
                               bottomLeadingRadius: 0,
                               bottomTrailingRadius: 0,
                               topTrailingRadius: 28,
                               style: .continuous)
            .fill(Color(white: 0.97))
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -2)
            .ignoresSafeArea(edges: .bottom)
    }

    private var handle: some View {
        Button(action: onDismiss) {
            Capsule()
                .fill(Color.black.opacity(0.2))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12).onEnded { value in
                if value.translation.height > 30 { onDismiss() }
            }
        )
        .accessibilityLabel("Close shapes")
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ShapeKind.pickerKinds) { kind in
                tile(for: kind)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 40)
    }

    private func glyphSize(for kind: ShapeKind) -> CGSize {
        let aspect: CGFloat = kind.defaultSize.width / kind.defaultSize.height
        let box: CGFloat = 36
        if aspect >= 1 {
            return CGSize(width: box, height: box / aspect)
        }
        return CGSize(width: box * aspect, height: box)
    }

    private func glyph(for kind: ShapeKind) -> some View {
        let size: CGSize = glyphSize(for: kind)
        return KindShape(kind: kind)
            .fill(Color(white: 0.42))
            .frame(width: size.width, height: size.height)
    }

    /// The preview shown while dragging a shape out of the panel (with the 56% shadow).
    private func dragPreview(for kind: ShapeKind) -> some View {
        glyph(for: kind)
            .level2Shadow()
            .padding(12)
    }

    private func tile(for kind: ShapeKind) -> some View {
        let isSelected: Bool = (kind == selectedKind)
        return Button {
            onSelect(kind)
        } label: {
            glyph(for: kind)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .contentShape(Rectangle())
        }
        .buttonStyle(ShapeTileStyle(isSelected: isSelected))
        .draggable("shape:\(kind.rawValue)") {
            dragPreview(for: kind)
        }
        .accessibilityLabel(kind.title)
        .accessibilityHint("Adds this shape to the canvas. You can also drag it onto the canvas.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Light tile with a thin border, an orange ring when selected, and a press effect.
struct ShapeTileStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed: Bool = configuration.isPressed
        let fillOpacity: Double = pressed ? 0.95 : 0.65
        let borderColor: Color = isSelected ? Level2Theme.orange : Color.black.opacity(0.08)
        let borderWidth: CGFloat = isSelected ? 2 : 1
        return configuration.label
            .background(Color.white.opacity(fillOpacity), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

// MARK: - Level 2 Progress (in memory, so Pause keeps your work)

/// Holds the drawing, shapes and answer outside the view. Leaving with `pause` pops Level2View,
/// so without this the work would be lost. Cleared after a completed submission.
@Observable
final class Level2Progress {
    static let shared = Level2Progress()

    var model = EditorModel()
    var answer = ""
    var isSubmitted = false

    func reset() {
        model = EditorModel()
        answer = ""
        isSubmitted = false
    }
}

// MARK: - Answer Window (compact centered card, not a sheet)

struct AnswerWindow: View {
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    @State private var draft: String
    @FocusState private var isFocused: Bool

    init(initialAnswer: String,
         onCreate: @escaping (String) -> Void,
         onCancel: @escaping () -> Void) {
        self.onCreate = onCreate
        self.onCancel = onCancel
        _draft = State(initialValue: initialAnswer)
    }

    private var cleaned: String {
        let trimmed: String = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(Level2Layout.maxAnswerLength))
    }

    private var isValid: Bool { !cleaned.isEmpty }

    // CHANGED: نفس تصميم بطاقة الكتابة في ليفل ١ و٣
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            field
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 312, height: 161, alignment: .top)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { onCancel() }
        .onAppear { isFocused = true }
    }

    private var header: some View {
        HStack {
            // cancel رمادي (نفس ليفل ١ و٣)
            Button("cancel", action: onCancel)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "6B6B66"))

            Spacer()

            createButton
        }
    }

    // create برتقالي (نفس ليفل ١ و٣)
    private var createButton: some View {
        Button(action: create) {
            Text("create")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 26)
                .background(Capsule().fill(Color.primaryOrange))
        }
        .opacity(isValid ? 1 : 0.4)     // باهت لين يكتب شي
        .disabled(!isValid)
    }

    private var field: some View {
        TextField("Write what you created!", text: $draft)   // CHANGED: نفس خط ليفل ١ و٣
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "111111"))
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit { create() }
            .onChange(of: draft) { _, newValue in
                if newValue.count > Level2Layout.maxAnswerLength {
                    draft = String(newValue.prefix(Level2Layout.maxAnswerLength))
                }
            }
            .accessibilityLabel("Your answer")
            .accessibilityHint("Up to \(Level2Layout.maxAnswerLength) characters.")
    }

    private func create() {
        guard isValid else { return }
        onCreate(cleaned)
    }
}

// MARK: - Level 2 Screen

struct Level2View: View {
    /// Called once when the challenge is submitted with Done.
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private let progress = Level2Progress.shared

    @State private var isDrawing = false
    @State private var showShapes = false
    @State private var showAnswerWindow = false
    @State private var showClearConfirmation = false
    @State private var showEditHint = false
    @State private var hasShownHint = false
    @State private var showPause = false
    @State private var showReward = false

    // ---------- NEW: النجوم والحفظ ----------
    private let levelNumber = 2
    private let levelStars = 20                      // CHANGED: نجوم الليفل كاملة (تنعطى مرة وحدة لما يكمّل الخطوتين)

    // النجوم محفوظة في الجوال (نفس المفتاح حق ليفل ١ و٣)
    @AppStorage(GameStorage.starsKey) private var totalStars = 0

    // CHANGED: كم نجمة أخذ من هالليفل (٠ أو ٢٠)
    @State private var givenStars = 0
    @State private var pendingStars = 0              // النجوم اللي بتنضاف لما توصل النجمة الطايرة

    // النجمة الطايرة (من LevelHelpers)
    @State private var isStarFlying = false
    @State private var flyStart: CGPoint = .zero
    @State private var badgeFrame: CGRect = .zero
    @State private var canvasFrame: CGRect = .zero
    @State private var badgeBump = false

    // النقطة اللي توصل لها النجمة (النجمة الصغيرة في العداد)
    private var badgeStarPoint: CGPoint {
        CGPoint(x: badgeFrame.minX + 19, y: badgeFrame.midY)
    }

    // النجوم اللي جمعها في هالليفل (تطلع في الريوارد)
    private var earnedInThisLevel: Int { givenStars }

    // CHANGED: كم نجمة **يستاهل** الحين؟
    // لازم يكون رسم/حط شكل **و** كتب إجابة → ٢٠، غير كذا → ٠
    private var deservedStars: Int {
        (model.hasEdits && hasAnswer) ? levelStars : 0
    }

    private var model: EditorModel { progress.model }
    private var answer: String { progress.answer }
    private var hasAnswer: Bool { !answer.isEmpty }

    /// The bottom button appears after a real canvas edit, and never over a panel, window or the pen tools.
    private var showAction: Bool {
        model.hasEdits && !showShapes && !isDrawing && !showAnswerWindow
    }

    private var hideMainControls: Bool { showShapes || showAnswerWindow }

    /// Kind of the shape selected on the canvas, used for the selected state in the panel.
    private var selectedKind: ShapeKind? {
        guard let id = model.selectedID else { return nil }
        return model.items.first(where: { $0.id == id })?.kind
    }

    var body: some View {
        ZStack {
            Level2Theme.cream.ignoresSafeArea()
            mainLayout
            floatingLayer
            actionLayer
            answerLayer
        }
        // NEW: النجمة الطايرة من الملف المشترك
        .flyingStar(isFlying: $isStarFlying, from: flyStart, to: badgeStarPoint) {
            starArrived()
        }
        .coordinateSpace(.named("screen"))
        // NEW: أول ما تفتح الصفحة نرجّع الإجابة والنجوم اللي أخذها قبل
        .onAppear(perform: loadSaved)
        // CHANGED: كل ما تغيّر اللي يستاهله (أضاف إجابة، مسح الرسم، undo...) نحدّث النجوم
        .onChange(of: deservedStars) { _, newValue in
            updateStars(to: newValue)
        }
        .pausePage(isPresented: $showPause,
                   message: PauseMessages.level2,      // NEW: عبارة الـ Pause حق هالليفل
                   onPause: { dismiss() },
                   onBack: {})
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Clear the canvas?",
                            isPresented: $showClearConfirmation,
                            titleVisibility: .visible) {
            Button("Clear Canvas", role: .destructive) {
                model.clearAll()
                updateStars(to: deservedStars)           // NEW: مسح كل شي → ننقص النجوم على طول
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your shapes and pen strokes. The stop sign stays. You can undo this.")
        }
        .onChange(of: isDrawing) { _, drawing in
            if drawing { model.select(nil) }
        }
        .onDisappear {
            if progress.isSubmitted { progress.reset() }
        }
        .animation(.easeInOut(duration: 0.25), value: showShapes)
        .animation(.easeInOut(duration: 0.2), value: showAction)
        .animation(.easeInOut(duration: 0.2), value: showEditHint)
        .animation(.easeInOut(duration: 0.2), value: showAnswerWindow)
        .animation(.easeInOut(duration: 0.25), value: showReward)
        .preferredColorScheme(.light)
        // CHANGED: صفحة الريوارد تنفتح بنفس طريقة ليفل ١ (fullScreenCover)
        .fullScreenCover(isPresented: $showReward) {
            RewardPopupView(
                xp: 10,
                coins: 350,
                stars: earnedInThisLevel,            // النجوم اللي جمعها في هالليفل
                tip: LevelTips.level2,               // التيب من LevelHelpers
                onDone: {
                    showReward = false
                    onComplete()                     // CHANGED: نفتح الليفل اللي بعده هنا (مو قبل الريوارد)
                    dismiss()                        // نرجع للماب
                }
            )
        }
    }

    // MARK: Layout

    private func canvasSide(for size: CGSize) -> CGFloat {
        let widthLimit: CGFloat = size.width - 40
        let heightLimit: CGFloat = size.height * 0.5
        let smallest: CGFloat = min(widthLimit, heightLimit)
        let capped: CGFloat = min(smallest, Level2Layout.maxCanvas)
        return max(0, capped)
    }

    private var mainLayout: some View {
        GeometryReader { proxy in
            let side: CGFloat = canvasSide(for: proxy.size)
            VStack(spacing: 0) {
                backArrow
                sentence
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                canvas(side: side)
                    .readFrame { canvasFrame = $0 }      // NEW: مكان اللوحة (النجمة تطير منها)
                    .padding(.top, 20)
                controls
                    .opacity(hideMainControls ? 0 : 1)
                    .allowsHitTesting(!hideMainControls)
                    .accessibilityHidden(hideMainControls)
                    .padding(.top, 12)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func canvas(side: CGFloat) -> some View {
        CanvasCard(
            model: model,
            side: side,
            isDrawing: isDrawing,
            onDropShape: { kind, center in addShape(kind, at: center) }
        )
    }

    // MARK: Back arrow (opens the shared Pause page)

    private var backArrow: some View {
        HStack {
            Button(action: openPause) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Pause")
            .accessibilityHint("Opens the pause menu. Your work is kept.")
            Spacer()

            // NEW: عداد النجوم
            Level2StarBadge(count: totalStars)
                .scaleEffect(badgeBump ? 1.18 : 1)       // نبضة لما توصل النجمة
                .readFrame { badgeFrame = $0 }           // نحفظ مكان العداد
        }
        .padding(.horizontal, 12)
    }

    // MARK: Sentence

    private var highlightedWords: some View {
        HStack(spacing: 6) {
            Text("This is not a")
            Text("stop sign")
                .padding(.horizontal, 10)
                .padding(.vertical, 1)
                .background(Level2Theme.highlight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var answerLine: some View {
        HStack(spacing: 6) {
            Text("this is")
                .layoutPriority(1)
            answerContent
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var answerContent: some View {
        if hasAnswer {
            editableAnswer
        } else {
            Text(".......")
        }
    }

    /// The underlined answer is itself the edit control (no separate Edit button).
    private var editableAnswer: some View {
        Button(action: editAnswer) {
            Text(answer)
                .underline(true, color: Level2Theme.answerRed)
                .foregroundStyle(Level2Theme.answerRed)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { editHint }
        .accessibilityLabel("Your answer: \(answer)")
        .accessibilityHint("Double tap to edit your answer.")
    }

    /// Subtle first-use hint. It is an overlay, so it never changes the title layout.
    @ViewBuilder
    private var editHint: some View {
        if showEditHint {
            Text("Tap to edit")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.5))
                .offset(y: 14)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
        }
    }

    private var sentence: some View {
        VStack(spacing: 4) {
            highlightedWords
            answerLine
        }
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .frame(maxWidth: .infinity)
    }

    // MARK: Controls

    private var controls: some View {
        EditorToolbar(
            isDrawing: isDrawing,
            isShowingShapes: showShapes,
            canUndo: model.canUndo,
            canRedo: model.canRedo,
            canClear: model.hasEdits,
            onPen: togglePen,
            onShapes: toggleShapes,
            onUndo: {
                model.undo()
                updateStars(to: deservedStars)           // NEW: نحدّث النجوم بعد undo
            },
            onRedo: {
                model.redo()
                updateStars(to: deservedStars)           // NEW: نحدّث النجوم بعد redo
            },
            onClear: { showClearConfirmation = true }
        )
        .frame(maxWidth: Level2Layout.maxCanvas)
        .padding(.horizontal, 20)
    }

    /// Toolbar stacked directly above the shapes panel, in the same hierarchy.
    @ViewBuilder
    private var floatingLayer: some View {
        if showShapes {
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                controls
                ShapesPanel(selectedKind: selectedKind,
                            onSelect: { kind in addShape(kind, at: nil) },
                            onDismiss: { showShapes = false })
                    .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: Answer window layer

    /// Dimmed background with a compact card at about 42% of the screen height, over the canvas.
    /// The toolbar sits above the keyboard, visible but not tappable while the window is open.
    @ViewBuilder
    private var answerLayer: some View {
        if showAnswerWindow {
            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                        AnswerWindow(initialAnswer: answer,
                                     onCreate: saveAnswer,
                                     onCancel: closeAnswerWindow)
                            .position(x: proxy.size.width / 2,
                                      y: proxy.size.height * 0.42)
                    }
                }
                .ignoresSafeArea(.keyboard)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    controls
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .padding(.bottom, 8)
                }
            }
            .transition(.opacity)
        }
    }

    // MARK: Bottom action (Add Answer, then Done)

    @ViewBuilder
    private var actionLayer: some View {
        if showAction {
            VStack {
                Spacer(minLength: 0)
                actionButton
                    .padding(.bottom, 24)
            }
            .transition(.opacity)
        }
    }

    private var actionButton: some View {
        let title: String = hasAnswer ? "Done" : "Add Answer"
        let hint: String = hasAnswer ? "Submits your challenge." : "Opens a field to write what you created."
        return Button(action: actionTapped) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 148, height: 48)
                .background(Level2Theme.orange, in: Capsule())
        }
        .disabled(progress.isSubmitted)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    // MARK: Actions

    private func togglePen() {
        isDrawing.toggle()
        if isDrawing { showShapes = false }
    }

    private func toggleShapes() {
        if !showShapes { isDrawing = false }
        showShapes.toggle()
    }

    private func addShape(_ kind: ShapeKind, at center: CGPoint?) {
        model.addItem(kind: kind, at: center)
        isDrawing = false
        showShapes = false
    }

    private func openPause() {
        showShapes = false
        showAnswerWindow = false
        isDrawing = false
        showPause = true
    }

    private func actionTapped() {
        if hasAnswer {
            submit()
        } else {
            presentAnswerWindow()
        }
    }

    /// The answer window and the shapes panel are never shown together.
    private func presentAnswerWindow() {
        showShapes = false
        isDrawing = false
        showAnswerWindow = true
    }

    private func editAnswer() {
        showEditHint = false
        presentAnswerWindow()
    }

    private func closeAnswerWindow() {
        showAnswerWindow = false
    }

    /// Saving an answer only updates the title. It never submits the challenge.
    private func saveAnswer(_ value: String) {
        progress.answer = value
        GameStorage.saveAnswer(value, level: levelNumber)   // NEW: نحفظ الإجابة في الجوال
        showAnswerWindow = false
        guard !hasShownHint else { return }
        hasShownHint = true
        showEditHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { showEditHint = false }
    }

    /// Runs once, so repeated taps can't trigger the reward twice.
    private func submit() {
        // CHANGED: لازم يكون رسم/حط شكل **و** كتب إجابة، وإلا ما يقدر يخلص الليفل
        guard model.hasEdits, hasAnswer, !progress.isSubmitted else { return }
        progress.isSubmitted = true
        GameStorage.markLevelCompleted(levelNumber)          // NEW: خلّص → النجوم تثبت وما تنقص
        model.select(nil)
        // CHANGED: شلنا onComplete() من هنا ونقلناه لزر Done في الريوارد (نفس ليفل ١)
        // لأنه لو انستدعى هنا، الماب ممكن يسكّر الليفل قبل ما تطلع صفحة الريوارد
        showReward = true
    }

    // MARK: NEW: النجوم

    /// نرجّع الإجابة المحفوظة، ونعرف كم نجمة أخذ قبل
    private func loadSaved() {
        if progress.answer.isEmpty {
            progress.answer = GameStorage.loadAnswer(level: levelNumber)
        }
        givenStars = GameStorage.starsGiven(level: levelNumber)
    }

    /// يخلي نجوم الليفل = اللي يستاهله: يزيد لو كمّل، وينقص لو حذف
    private func updateStars(to target: Int) {
        // 1) إذا خلّص الليفل قبل، النجوم ثابتة وما نغيرها
        if GameStorage.isLevelCompleted(levelNumber) { return }

        // 2) نحسب الفرق بين اللي يستاهله واللي أخذه
        let difference = target - givenStars
        if difference == 0 { return }

        // 3) نحفظ الرقم الجديد
        givenStars = target
        GameStorage.setStarsGiven(target, level: levelNumber)

        if difference > 0 {
            // 4أ) زادت → نطيّر النجمة من نص اللوحة للعداد
            pendingStars = difference
            flyStart = CGPoint(x: canvasFrame.midX, y: canvasFrame.midY)
            isStarFlying = true
        } else {
            // 4ب) نقصت (حذف الرسم أو سوى undo) → ننقص من العداد على طول
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                totalStars = max(0, totalStars + difference)
            }
        }
    }

    /// لما توصل النجمة للعداد: يزيد والعداد ينبض
    private func starArrived() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            totalStars += pendingStars               // ينحفظ تلقائياً
            pendingStars = 0
            badgeBump = true
        } completion: {
            withAnimation(.spring(response: 0.3)) { badgeBump = false }
        }
    }
}

// MARK: - NEW: عداد النجوم حق ليفل ٢

private struct Level2StarBadge: View {
    var count: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 1, green: 0.79, blue: 0.2))
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(.horizontal, 10)
        .frame(height: 29)
        .background(Color(red: 0.99, green: 0.96, blue: 0.86), in: Capsule())
        .overlay(Capsule().stroke(Color(red: 0.90, green: 0.78, blue: 0.48), lineWidth: 1))
        .accessibilityLabel("\(count) stars")
    }
}

// MARK: - Preview

#Preview {
    Level2View()
}
