import SwiftUI
import PencilKit
import UIKit

// MARK: - Theme, Layout, Shadow

enum Level2Theme {
    static let cream = Color(red: 0.985, green: 0.975, blue: 0.93)
    static let highlight = Color(red: 0.80, green: 0.85, blue: 0.62)
    static let orange = Color(red: 0.85, green: 0.38, blue: 0.04)
    static let canvasBorder = Color.black.opacity(0.14)
}

enum Level2Layout {
    static let maxCanvas: CGFloat = 520
    static let sheetHeight: CGFloat = 240
    static let handleOffset: CGFloat = 14
    static let canvasSpace = "EditorCanvasSpace"
}

enum Level2Shadow {
    static let color: Color = Color.black.opacity(0.56)
    static let radius: CGFloat = 6
    static let x: CGFloat = 0
    static let y: CGFloat = 4
}

// MARK: - Shape Kind

enum ShapeKind: String, CaseIterable, Identifiable {
    case circle, square, star, triangle, pentagon, parallelogram, semicircle, rectangle, octagon

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
struct CanvasItem: Identifiable, Equatable {
    let id: UUID
    var kind: ShapeKind
    var palette: PaletteColor
    var center: CGPoint
    var scale: CGFloat
    var rotation: CGFloat // radians

    init(id: UUID = UUID(),
         kind: ShapeKind,
         palette: PaletteColor,
         center: CGPoint,
         scale: CGFloat = 1,
         rotation: CGFloat = 0) {
        self.id = id
        self.kind = kind
        self.palette = palette
        self.center = center
        self.scale = scale
        self.rotation = rotation
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

// MARK: - History Snapshot

/// Everything the user can change. The original stop sign is NOT part of this.
struct EditorSnapshot {
    var items: [CanvasItem]
    var drawing: PKDrawing
}

// MARK: - Shape Paths

struct KindShape: Shape {
    let kind: ShapeKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .circle:
            return Path(ellipseIn: rect)
        case .square, .rectangle:
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
        var points: [CGPoint] = []
        for i in 0..<sides {
            let step: CGFloat = 2 * CGFloat.pi / CGFloat(sides)
            let angle: CGFloat = -CGFloat.pi / 2 + CGFloat(i) * step
            let x: CGFloat = rect.midX + radius * cos(angle)
            let y: CGFloat = rect.midY + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }

    private func starPath(in rect: CGRect) -> Path {
        let outer: CGFloat = min(rect.width, rect.height) / 2
        let inner: CGFloat = outer * 0.42
        var points: [CGPoint] = []
        for i in 0..<10 {
            let radius: CGFloat = (i % 2 == 0) ? outer : inner
            let angle: CGFloat = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 5
            let x: CGFloat = rect.midX + radius * cos(angle)
            let y: CGFloat = rect.midY + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }

    /// Flat edge on top, curve below.
    private func semicirclePath(in rect: CGRect) -> Path {
        let steps = 48
        var points: [CGPoint] = []
        for i in 0...steps {
            let t: CGFloat = CGFloat.pi * CGFloat(i) / CGFloat(steps)
            let x: CGFloat = rect.midX + rect.width / 2 * cos(t)
            let y: CGFloat = rect.minY + rect.height * sin(t)
            points.append(CGPoint(x: x, y: y))
        }
        return polygon(points)
    }
}

// MARK: - Editor Model (user shapes + drawing + history)

/// Owns everything the user can edit. The original stop sign is deliberately not stored here.
@Observable
final class EditorModel {
    var items: [CanvasItem] = []
    var drawing = PKDrawing()
    var drawingRevision = 0
    var selectedID: UUID?
    var paletteID: UUID?

    /// Transient copy of the shape being dragged, resized or rotated. Committed once per gesture.
    private(set) var live: CanvasItem?
    private var liveBase: CanvasItem?

    private(set) var undoStack: [EditorSnapshot] = []
    private(set) var redoStack: [EditorSnapshot] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasDrawing: Bool { !drawing.strokes.isEmpty }

    /// True when the canvas holds any user-made content. Drives Done and the trash button.
    var hasEdits: Bool { !items.isEmpty || hasDrawing }

    private var current: EditorSnapshot {
        EditorSnapshot(items: items, drawing: drawing)
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
        drawing = snapshot.drawing
        drawingRevision += 1
        if let id = selectedID, !items.contains(where: { $0.id == id }) { selectedID = nil }
        if let id = paletteID, !items.contains(where: { $0.id == id }) { paletteID = nil }
    }

    // MARK: Drawing

    func drawingChanged(to newDrawing: PKDrawing) {
        let old: Data = drawing.dataRepresentation()
        let new: Data = newDrawing.dataRepresentation()
        guard old != new else { return }
        commit { drawing = newDrawing }
    }

    /// Removes every user shape and stroke as one undoable step. The stop sign is unaffected.
    func clearAll() {
        guard hasEdits else { return }
        commit {
            items = []
            drawing = PKDrawing()
            drawingRevision += 1
            selectedID = nil
            paletteID = nil
        }
        live = nil
        liveBase = nil
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
        let raw = CanvasItem(kind: kind, palette: .white, center: proposed)
        let item: CanvasItem = Self.normalized(raw)
        commit {
            items.append(item)
            selectedID = item.id
            paletteID = nil
        }
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

    func setColor(_ id: UUID, to palette: PaletteColor) {
        transform(id) { $0.palette = palette }
    }

    func deleteItem(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        commit {
            items.removeAll { $0.id == id }
            if selectedID == id { selectedID = nil }
            if paletteID == id { paletteID = nil }
        }
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
        canvas.drawing = model.drawing
        context.coordinator.isApplying = false
        context.coordinator.appliedRevision = revision
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEnabled
        if context.coordinator.appliedRevision != revision {
            context.coordinator.isApplying = true
            canvas.drawing = model.drawing
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

// MARK: - Original Stop Sign

/// The activity's starting element. It is not an item, so it cannot be selected, moved or cleared.
struct StopSignView: View {
    let side: CGFloat

    var body: some View {
        let size: CGSize = ShapeKind.octagon.defaultSize
        let width: CGFloat = size.width * side
        let height: CGFloat = size.height * side
        KindShape(kind: .octagon)
            .fill(PaletteColor.red.color)
            .frame(width: width, height: height)
            .shadow(color: Level2Shadow.color, radius: Level2Shadow.radius, x: Level2Shadow.x, y: Level2Shadow.y)
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
    let onBackgroundTap: () -> Void
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

    private var content: some View {
        ZStack(alignment: .topLeading) {
            backgroundTapLayer
            StopSignView(side: side)
            ForEach(model.items) { item in
                ShapeItemView(item: model.displayed(item), side: side, model: model)
            }
            DrawingCanvas(model: model,
                          revision: model.drawingRevision,
                          isEnabled: isDrawing)
                .allowsHitTesting(isDrawing)
        }
    }

    private var backgroundTapLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                model.select(nil)
                onBackgroundTap()
            }
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
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { _ in
                model.commitLive()
            }
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
            .shadow(color: Level2Shadow.color, radius: Level2Shadow.radius, x: Level2Shadow.x, y: Level2Shadow.y)
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
            onDelete: {
                model.deleteItem(item.id)
            }
        )
        .presentationCompactAdaptation(.popover)
    }
}

/// Accessibility for a shape, kept separate so the view body stays easy to type-check.
struct ShapeAccessibility: ViewModifier {
    let item: CanvasItem
    let model: EditorModel
    let isSelected: Bool

    private var traits: AccessibilityTraits {
        isSelected ? [.isButton, .isSelected] : [.isButton]
    }

    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            .accessibilityLabel("\(item.palette.name) \(item.kind.title)")
            .accessibilityHint("Double tap to select. Double tap again to change its color.")
            .accessibilityAddTraits(traits)
            .accessibilityAction(named: "Change Color") {
                model.select(item.id)
                model.paletteID = item.id
            }
            .accessibilityAction(named: "Rotate 15 degrees") {
                model.transform(item.id) { $0.rotation += CGFloat.pi / 12 }
            }
            .accessibilityAction(named: "Make Larger") {
                model.transform(item.id) { $0.scale *= 1.15 }
            }
            .accessibilityAction(named: "Make Smaller") {
                model.transform(item.id) { $0.scale /= 1.15 }
            }
            .accessibilityAction(named: "Delete Shape") {
                model.deleteItem(item.id)
            }
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
        let diagonal: CGFloat = hypot(base.size.width, base.size.height) * side / 2
        let cornerDistance: CGFloat = max(diagonal, 1)
        let startDistance: CGFloat = hypot(value.startLocation.x - c.x, value.startLocation.y - c.y)
        let distance: CGFloat = hypot(value.location.x - c.x, value.location.y - c.y)
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
                let delta: CGFloat = (direction == .increment) ? CGFloat.pi / 12 : -CGFloat.pi / 12
                model.transform(item.id) { $0.rotation += delta }
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
                let factor: CGFloat = (direction == .increment) ? 1.15 : 1 / 1.15
                model.transform(item.id) { $0.scale *= factor }
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

    private let columns: [GridItem] = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5)

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 6) {
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
        .frame(width: 5 * 44 + 4 * 6 + 28)
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

// MARK: - Shape Picker Sheet

struct ShapePickerSheet: View {
    /// Kind of the shape currently selected on the canvas, if any. Shown with an orange ring.
    let selectedKind: ShapeKind?
    let onSelect: (ShapeKind) -> Void

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ShapeKind.pickerKinds) { kind in
                tile(for: kind)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .frame(maxHeight: .infinity, alignment: .top)
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

    /// The preview shown while dragging a shape out of the sheet (with the 56% shadow).
    private func dragPreview(for kind: ShapeKind) -> some View {
        glyph(for: kind)
            .shadow(color: Level2Shadow.color, radius: Level2Shadow.radius, x: Level2Shadow.x, y: Level2Shadow.y)
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

// MARK: - Level 2 Screen

struct Level2View: View {
    var onComplete: () -> Void = {}
    @State private var model = EditorModel()
    @State private var answer = ""
    @State private var isDrawing = false
    @State private var showShapes = false
    @State private var showClearConfirmation = false
    @FocusState private var isEditing: Bool

    /// Only the shape sheet floats the toolbar above itself.
    private var floatingControls: Bool { showShapes }

    /// While typing, the drawing toolbar is hidden (the keyboard has its own Done bar).
    private var hideControls: Bool { showShapes || isEditing }

    /// Done appears only after a real canvas edit, and never over the sheet, keyboard or tool picker.
    private var showDone: Bool {
        model.hasEdits && !showShapes && !isEditing && !isDrawing
    }

    /// Kind of the shape selected on the canvas, used for the selected state in the sheet.
    private var selectedKind: ShapeKind? {
        guard let id = model.selectedID else { return nil }
        return model.items.first(where: { $0.id == id })?.kind
    }

    var body: some View {
        ZStack {
            Level2Theme.cream.ignoresSafeArea()
            mainLayout
            floatingLayer
            doneLayer
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isEditing = false }
                    .fontWeight(.semibold)
                    .foregroundStyle(Level2Theme.orange)
            }
        }
        .sheet(isPresented: $showShapes) { shapeSheet }
        .confirmationDialog("Clear the canvas?",
                            isPresented: $showClearConfirmation,
                            titleVisibility: .visible) {
            Button("Clear Canvas", role: .destructive) { model.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your shapes and pen strokes. The stop sign stays. You can undo this.")
        }
        .onChange(of: isEditing) { _, editing in
            if editing {
                showShapes = false
                isDrawing = false
            }
        }
        .onChange(of: isDrawing) { _, drawing in
            if drawing {
                model.select(nil)
                isEditing = false
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showShapes)
        .animation(.easeInOut(duration: 0.2), value: showDone)
        .preferredColorScheme(.light)
    }

    // MARK: Layout

    private func canvasSide(for size: CGSize) -> CGFloat {
        let widthLimit: CGFloat = size.width - 40
        let heightLimit: CGFloat = size.height * 0.5
        let side: CGFloat = min(widthLimit, heightLimit, Level2Layout.maxCanvas)
        return max(0, side)
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
                    .padding(.top, 20)
                controls
                    .opacity(hideControls ? 0 : 1)
                    .allowsHitTesting(!hideControls)
                    .accessibilityHidden(hideControls)
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
            onBackgroundTap: { isEditing = false },
            onDropShape: { kind, center in addShape(kind, at: center) }
        )
    }

    // MARK: Back arrow (appearance only, no action)

    private var backArrow: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
            Spacer()
        }
        .padding(.horizontal, 12)
        .accessibilityHidden(true)
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
            InlineAnswerField(text: $answer, focus: $isEditing) { isEditing = false }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture { isEditing = true }
    }

    private var sentence: some View {
        VStack(spacing: 4) {
            highlightedWords
            answerLine
        }
        .font(.title2.weight(.bold))
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
            onUndo: { model.undo() },
            onRedo: { model.redo() },
            onClear: { showClearConfirmation = true }
        )
        .frame(maxWidth: Level2Layout.maxCanvas)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var floatingLayer: some View {
        if floatingControls {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                controls
                    .padding(.bottom, Level2Layout.sheetHeight + 8)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .transition(.opacity)
        }
    }

    // MARK: Done

    @ViewBuilder
    private var doneLayer: some View {
        if showDone {
            VStack {
                Spacer(minLength: 0)
                doneButton
                    .padding(.bottom, 24)
            }
            .transition(.opacity)
        }
    }

    private var doneButton: some View {
        Button {
            isEditing = false
            model.select(nil)
            onComplete()
        } label: {
            Text("Done")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 132, height: 48)
                .background(Level2Theme.orange, in: Capsule())
        }
        .accessibilityLabel("Done")
        .accessibilityHint("Completes the activity.")
    }
    // MARK: Shape sheet

    private var shapeSheet: some View {
        ShapePickerSheet(selectedKind: selectedKind) { kind in addShape(kind, at: nil) }
            .presentationDetents([.height(Level2Layout.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(Level2Theme.cream)
    }

    // MARK: Actions

    private func togglePen() {
        isDrawing.toggle()
        if isDrawing { showShapes = false }
    }

    private func toggleShapes() {
        if !showShapes {
            isDrawing = false
            isEditing = false
        }
        showShapes.toggle()
    }

    private func addShape(_ kind: ShapeKind, at center: CGPoint?) {
        model.addItem(kind: kind, at: center)
        isDrawing = false
        showShapes = false
    }
}

// MARK: - Sentence Answer Field

struct InlineAnswerField: View {
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        let isFocused: Bool = focus.wrappedValue
        let highlightOpacity: Double = isFocused ? 0.16 : 0
        return sizer
            .overlay { field }
            .background(Level2Theme.orange.opacity(highlightOpacity),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onChange(of: text) { _, newValue in
                if newValue.count > 24 { text = String(newValue.prefix(24)) }
            }
    }

    /// Invisible text that gives the field the width of its content.
    private var sizer: some View {
        Text(text.isEmpty ? "......." : text)
            .opacity(0)
            .padding(.horizontal, 6)
    }

    private var field: some View {
        TextField("", text: $text, prompt: Text(".......").foregroundStyle(.black))
            .focused(focus)
            .submitLabel(.done)
            .onSubmit(onSubmit)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 6)
            .accessibilityLabel("Your answer")
            .accessibilityHint("Finish the sentence: this is")
    }
}

// MARK: - Preview

#Preview {
    Level2View()
}
