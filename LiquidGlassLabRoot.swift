import UIKit

@objc(LiquidGlassRootFactory)
public final class LiquidGlassRootFactory: NSObject {
    @objc public static func makeRootViewController() -> UIViewController {
        PhotosSystemTabController()
    }
}

// MARK: - Bottom bar (0.3.4 baseline; the first tab now hosts the test home)

@available(iOS 26.0, *)
private final class PhotosSystemTabController: UITabBarController {
    private enum Identifier {
        static let home = "com.xyy.liquidglasslab.home"
        static let featured = "com.xyy.liquidglasslab.featured"
        static let albums = "com.xyy.liquidglasslab.albums"
        static let shared = "com.xyy.liquidglasslab.shared"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        view.tintColor = .systemCyan
        tabBarMinimizeBehavior = .onScrollDown

        // 0.4.0: the first tab is a Douyin-like home (video feed, the top
        // category group with its two side buttons, the right action column).
        // The bar itself is unchanged: four regular tabs plus the Search tab.
        let homeTab = UITab(
            title: "首页",
            image: UIImage(systemName: "play.rectangle.fill"),
            identifier: Identifier.home
        ) { _ in
            DouyinHomeViewController()
        }

        let featuredTab = UITab(
            title: "精选集",
            image: UIImage(systemName: "rectangle.stack.fill"),
            identifier: Identifier.featured
        ) { _ in
            UINavigationController(
                rootViewController: PhotosGridViewController(kind: .featured)
            )
        }

        let albumsTab = UITab(
            title: "相簿",
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            identifier: Identifier.albums
        ) { _ in
            UINavigationController(
                rootViewController: PhotosGridViewController(kind: .albums)
            )
        }

        let sharedTab = UITab(
            title: "共享",
            image: UIImage(systemName: "person.2.fill"),
            identifier: Identifier.shared
        ) { _ in
            UINavigationController(
                rootViewController: PhotosGridViewController(kind: .shared)
            )
        }

        let searchTab = UISearchTab { _ in
            UINavigationController(
                rootViewController: PhotosSearchViewController()
            )
        }
        searchTab.automaticallyActivatesSearch = true

        tabs = [
            homeTab,
            featuredTab,
            albumsTab,
            sharedTab,
            searchTab,
        ]
        selectedTab = homeTab

        // Intentionally no bottomAccessory. UIKit alone owns the native
        // tab bar, its selected platter, scroll minimization, and Search tab.
    }
}

// MARK: - Lab settings (UserDefaults, applied live)

private func labClamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
    min(upper, max(lower, value))
}

private func labFormat(_ value: CGFloat, digits: Int = 1) -> String {
    String(format: "%.\(digits)f", Double(value))
}

private func labRect(_ rect: CGRect) -> String {
    "x\(labFormat(rect.minX)) y\(labFormat(rect.minY)) \(labFormat(rect.width))×\(labFormat(rect.height))"
}

private enum LabKey {
    static let groupImpl = "lab.top.groupImpl"
    static let sideImpl = "lab.top.sideImpl"
    static let groupCount = "lab.top.count"
    static let keepSingle = "lab.top.keepSingle"
    static let groupScale = "lab.top.groupScale"
    static let slotWidth = "lab.top.slotWidth"
    static let sideScale = "lab.top.sideScale"
    static let sideMargin = "lab.top.sideMargin"
    static let nearGroup = "lab.top.nearGroup"
    static let edgeEffect = "lab.top.edgeEffect"
    static let transparentBars = "lab.top.transparentBars"
    static let rightMaterial = "lab.right.material"
    static let rightScale = "lab.right.scale"
    static let rightSpacing = "lab.right.spacing"
    static let rightMargin = "lab.right.margin"
    static let rightBottom = "lab.right.bottom"
    static let bottomMinimize = "lab.bottom.minimize"
    static let appearance = "lab.appearance"

    static let all = [
        groupImpl, sideImpl, groupCount, keepSingle, groupScale, slotWidth,
        sideScale, sideMargin, nearGroup, edgeEffect, transparentBars,
        rightMaterial, rightScale, rightSpacing, rightMargin, rightBottom,
        bottomMinimize, appearance,
    ]
}

private enum LabSettings {
    static let didChange = Notification.Name("LiquidGlassLab.settingsDidChange")
    static let changedKey = "key"

    static func integer(_ key: String, _ fallback: Int) -> Int {
        UserDefaults.standard.object(forKey: key) == nil
            ? fallback
            : UserDefaults.standard.integer(forKey: key)
    }

    static func number(_ key: String, _ fallback: Double) -> Double {
        UserDefaults.standard.object(forKey: key) == nil
            ? fallback
            : UserDefaults.standard.double(forKey: key)
    }

    static func flag(_ key: String, _ fallback: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) == nil
            ? fallback
            : UserDefaults.standard.bool(forKey: key)
    }

    static func store(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
        NotificationCenter.default.post(
            name: didChange,
            object: nil,
            userInfo: [changedKey: key]
        )
    }

    static func reset() {
        for key in LabKey.all {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NotificationCenter.default.post(
            name: didChange,
            object: nil,
            userInfo: [changedKey: ""]
        )
    }

    /// 0 standalone UITabBar, 1 child UITabBarController (the tweak's
    /// structure), 2 navigation bar center item group.
    static var groupImpl: Int { labClamp(integer(LabKey.groupImpl, 0), 0, 2) }
    /// 0 navigation bar items (bar glass), 1 glass button Regular,
    /// 2 glass button Clear, 3 glass view Regular, 4 glass view Clear.
    static var sideImpl: Int { labClamp(integer(LabKey.sideImpl, 0), 0, 4) }
    static var groupCount: Int { labClamp(integer(LabKey.groupCount, 2), 1, 4) }
    static var keepSingleSelection: Bool { flag(LabKey.keepSingle, true) }
    static var groupScale: CGFloat { CGFloat(labClamp(number(LabKey.groupScale, 0.75), 0.5, 1.2)) }
    static var slotWidth: CGFloat { CGFloat(labClamp(number(LabKey.slotWidth, 76), 44, 120)) }
    static var sideScale: CGFloat { CGFloat(labClamp(number(LabKey.sideScale, 1.0), 0.6, 1.3)) }
    static var sideMargin: CGFloat { CGFloat(labClamp(number(LabKey.sideMargin, 16), 0, 40)) }
    static var nearGroup: Bool { flag(LabKey.nearGroup, false) }
    /// 0 hidden, 1 automatic, 2 soft, 3 hard.
    static var edgeEffect: Int { labClamp(integer(LabKey.edgeEffect, 0), 0, 3) }
    static var transparentBars: Bool { flag(LabKey.transparentBars, false) }
    /// 0 glass button Regular, 1 glass button Clear, 2 glass view Regular,
    /// 3 glass view Clear, 4 navigation bar item (bar glass, follows the
    /// system Liquid Glass setting like the top side buttons).
    static var rightMaterial: Int { labClamp(integer(LabKey.rightMaterial, 4), 0, 4) }
    static var rightScale: CGFloat { CGFloat(labClamp(number(LabKey.rightScale, 1.0), 0.6, 1.3)) }
    static var rightSpacing: CGFloat { CGFloat(labClamp(number(LabKey.rightSpacing, 14), 0, 30)) }
    static var rightMargin: CGFloat { CGFloat(labClamp(number(LabKey.rightMargin, 10), 0, 40)) }
    static var rightBottom: CGFloat { CGFloat(labClamp(number(LabKey.rightBottom, 24), 0, 200)) }
    static var bottomMinimize: Bool { flag(LabKey.bottomMinimize, true) }
    /// 0 follow system, 1 dark, 2 light.
    static var appearance: Int { labClamp(integer(LabKey.appearance, 1), 0, 2) }
}

// MARK: - Glass helpers

@available(iOS 26.0, *)
private enum LabGlass {
    static func buttonConfiguration(clear: Bool) -> UIButton.Configuration {
        clear ? UIButton.Configuration.clearGlass() : UIButton.Configuration.glass()
    }

    static func effect(clear: Bool) -> UIGlassEffect {
        let effect = UIGlassEffect(style: clear ? .clear : .regular)
        effect.isInteractive = true
        return effect
    }

    /// A class-side getter through the runtime (+[Class selector]), so this
    /// file does not depend on the Swift spelling of newer UIKit API.
    static func classValue(_ className: String, _ selectorName: String) -> AnyObject? {
        let selector = NSSelectorFromString(selectorName)
        guard let cls = NSClassFromString(className),
              let method = class_getClassMethod(cls, selector)
        else {
            return nil
        }
        typealias Getter = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>?
        let getter = unsafeBitCast(method_getImplementation(method), to: Getter.self)
        return getter(cls, selector)?.takeUnretainedValue()
    }

    /// UIKit's capsule corner configuration (iOS 26).
    @discardableResult
    static func applyCapsule(to view: UIView) -> Bool {
        guard view.responds(to: NSSelectorFromString("setCornerConfiguration:")),
              let configuration = classValue("UICornerConfiguration", "capsuleConfiguration")
        else {
            return false
        }
        view.setValue(configuration, forKey: "cornerConfiguration")
        return true
    }

    /// The scroll view's top edge effect (iOS 26): 0 hidden, 1 automatic,
    /// 2 soft, 3 hard.
    static func configureTopEdgeEffect(_ scrollView: UIScrollView, mode: Int) {
        guard scrollView.responds(to: NSSelectorFromString("topEdgeEffect")),
              let effect = scrollView.value(forKey: "topEdgeEffect") as? NSObject
        else {
            return
        }
        if effect.responds(to: NSSelectorFromString("setHidden:")) {
            effect.setValue(mode == 0, forKey: "hidden")
        }
        guard mode > 0,
              effect.responds(to: NSSelectorFromString("setStyle:"))
        else {
            return
        }
        let names = ["automaticStyle", "softStyle", "hardStyle"]
        if let style = classValue("UIScrollEdgeEffectStyle", names[labClamp(mode, 1, 3) - 1]) {
            effect.setValue(style, forKey: "style")
        }
    }

    /// UIScrollEdgeElementContainerInteraction (iOS 26): tells the feed that
    /// the top chrome sits over its top edge, so UIKit draws one edge effect
    /// behind it, as it does under a navigation bar.
    static func makeTopEdgeContainerInteraction(for scrollView: UIScrollView) -> UIInteraction? {
        guard let type = NSClassFromString("UIScrollEdgeElementContainerInteraction") as? NSObject.Type else {
            return nil
        }
        let object = type.init()
        guard object.responds(to: NSSelectorFromString("setScrollView:")),
              object.responds(to: NSSelectorFromString("setEdge:")),
              let interaction = object as? UIInteraction
        else {
            return nil
        }
        object.setValue(scrollView, forKey: "scrollView")
        object.setValue(UIRectEdge.top.rawValue, forKey: "edge")
        return interaction
    }

    /// The tab bar's glass platter (the capsule that holds the items).
    static func findPlatter(in root: UIView) -> UIView? {
        var queue: [UIView] = [root]
        var index = 0
        while index < queue.count && index < 300 {
            let view = queue[index]
            index += 1
            if NSStringFromClass(type(of: view)).contains("TabBarPlatterView"),
               !view.bounds.isEmpty,
               !view.isHidden {
                return view
            }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// Small controls (bar buttons) inside a bar, for the measurements panel.
    static func controls(in root: UIView) -> [UIView] {
        var result: [UIView] = []
        var queue: [UIView] = [root]
        var index = 0
        while index < queue.count && index < 300 && result.count < 8 {
            let view = queue[index]
            index += 1
            if view !== root,
               view is UIControl,
               !view.bounds.isEmpty,
               view.bounds.width < root.bounds.width * 0.6 {
                result.append(view)
                continue
            }
            queue.append(contentsOf: view.subviews)
        }
        return result
    }

    /// A category title drawn as a template image (the tab bar tints it).
    /// A bar scaled down by `layoutScale` gets a glyph drawn that much larger
    /// at a matching pixel density, so the text stays sharp after the scale.
    static func textGlyph(
        _ text: String,
        pointSize: CGFloat,
        layoutScale: CGFloat,
        displayScale: CGFloat
    ) -> UIImage {
        let scale = max(0.3, layoutScale)
        let font = UIFont.systemFont(ofSize: pointSize / scale, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
        ]
        let string = text as NSString
        let measured = string.size(withAttributes: attributes)
        let size = CGSize(
            width: ceil(measured.width) + 2,
            height: ceil(measured.height) + 2
        )
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = max(1, displayScale * scale)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            string.draw(at: CGPoint(x: 1, y: 1), withAttributes: attributes)
        }
        return image.withRenderingMode(.alwaysTemplate)
    }
}

/// A round control in the right column, whichever glass draws it.
@available(iOS 26.0, *)
private protocol LabCircle: UIView {
    func setTint(_ color: UIColor)
}

/// A circular glass control at its real size. Kinds: UIKit's glass button
/// configurations (Regular / Clear), or an interactive UIGlassEffect view
/// (Regular / Clear) holding a plain button.
@available(iOS 26.0, *)
private final class GlassCircle: UIView, LabCircle {
    enum Kind: Int {
        case buttonRegular = 0
        case buttonClear = 1
        case effectRegular = 2
        case effectClear = 3
    }

    let button: UIButton
    private let glassView: UIVisualEffectView?
    private var capsuleApplied = false

    init(kind: Kind, symbol: String, pointSize: CGFloat, tint: UIColor = .label) {
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: pointSize,
            weight: .semibold
        )
        switch kind {
        case .buttonRegular, .buttonClear:
            var configuration = LabGlass.buttonConfiguration(clear: kind == .buttonClear)
            configuration.image = UIImage(systemName: symbol)
            configuration.preferredSymbolConfigurationForImage = symbolConfiguration
            configuration.baseForegroundColor = tint
            configuration.cornerStyle = .capsule
            configuration.contentInsets = .zero
            button = UIButton(configuration: configuration)
            glassView = nil
        case .effectRegular, .effectClear:
            let effectView = UIVisualEffectView(
                effect: LabGlass.effect(clear: kind == .effectClear)
            )
            var configuration = UIButton.Configuration.plain()
            configuration.image = UIImage(systemName: symbol)
            configuration.preferredSymbolConfigurationForImage = symbolConfiguration
            configuration.baseForegroundColor = tint
            configuration.contentInsets = .zero
            button = UIButton(configuration: configuration)
            glassView = effectView
        }
        super.init(frame: .zero)
        backgroundColor = .clear
        if let glassView {
            addSubview(glassView)
            glassView.contentView.addSubview(button)
        } else {
            addSubview(button)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let glassView {
            glassView.frame = bounds
            if !capsuleApplied {
                capsuleApplied = LabGlass.applyCapsule(to: glassView)
            }
            if !capsuleApplied {
                glassView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
                glassView.layer.cornerCurve = .continuous
            }
            button.frame = glassView.contentView.bounds
        } else {
            button.frame = bounds
        }
    }

    func setTint(_ color: UIColor) {
        guard var configuration = button.configuration else { return }
        configuration.baseForegroundColor = color
        button.configuration = configuration
    }
}

/// A navigation bar that only takes touches on its items.
@available(iOS 26.0, *)
private final class ItemOnlyNavigationBar: UINavigationBar {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}

/// A round control drawn by a one-item navigation bar, so its glass is bar
/// glass: the material of the top side buttons and the tab bar, which
/// follows the system Liquid Glass setting (Clear / Tinted). The glass
/// buttons and glass views do not. UIKit keeps the item at its own size;
/// the bar is scaled so the item matches the wanted diameter.
@available(iOS 26.0, *)
private final class BarGlassCircle: UIView, LabCircle {
    private let bar = ItemOnlyNavigationBar()
    private let item: UIBarButtonItem
    private let symbol: String
    private let pointSize: CGFloat
    private var tint: UIColor
    private var imageKey: (scale: CGFloat, tint: UIColor)?

    init(symbol: String, pointSize: CGFloat, tint: UIColor = .label, action: (() -> Void)? = nil) {
        self.symbol = symbol
        self.pointSize = pointSize
        self.tint = tint
        item = UIBarButtonItem(
            image: nil,
            primaryAction: action.map { action in UIAction { _ in action() } }
        )
        super.init(frame: .zero)
        backgroundColor = .clear
        bar.tintColor = .label
        bar.directionalLayoutMargins = .zero
        let navigationItem = UINavigationItem(title: "")
        navigationItem.leftBarButtonItem = item
        bar.setItems([navigationItem], animated: false)
        addSubview(bar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTint(_ color: UIColor) {
        tint = color
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        // Lay the bar out unscaled, measure UIKit's item, then scale and
        // place the bar so that item is centered here at this view's size.
        bar.transform = .identity
        let height = max(44, bar.sizeThatFits(CGSize(width: 120, height: 200)).height)
        bar.bounds = CGRect(x: 0, y: 0, width: 120, height: height)
        bar.center = CGPoint(x: bounds.midX, y: bounds.midY)
        updateImage(scale: bounds.width / 44)
        bar.layoutIfNeeded()
        guard let control = LabGlass.controls(in: bar).first, control.bounds.width > 0 else {
            return
        }
        let scale = bounds.width / control.bounds.width
        let frame = control.convert(control.bounds, to: bar)
        let offset = CGPoint(x: frame.midX - bar.bounds.midX, y: frame.midY - bar.bounds.midY)
        bar.transform = CGAffineTransform(scaleX: scale, y: scale)
        bar.center = CGPoint(x: bounds.midX - offset.x * scale, y: bounds.midY - offset.y * scale)
    }

    /// The symbol is drawn at pointSize / scale, so after the bar's scale it
    /// shows at the column's own point size.
    private func updateImage(scale: CGFloat) {
        if let imageKey, abs(imageKey.scale - scale) < 0.001, imageKey.tint == tint {
            return
        }
        imageKey = (scale, tint)
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize / scale, weight: .semibold)
        var image = UIImage(systemName: symbol, withConfiguration: configuration)
        // A tinted bar item gets tinted glass, so the color goes in the image.
        if tint != .label {
            image = image?.withTintColor(tint, renderingMode: .alwaysOriginal)
        }
        item.image = image
    }
}

/// A standalone navigation bar whose empty, full-width areas let touches
/// through to the feed; its bar buttons keep theirs.
@available(iOS 26.0, *)
private final class PassThroughNavigationBar: UINavigationBar {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event), hit !== self else {
            return nil
        }
        let frame = hit.convert(hit.bounds, to: self)
        return frame.width < bounds.width * 0.9 ? hit : nil
    }
}

// MARK: - Top category group (native tab bar glass at its own size)

/// The category group. Mode .standalone is a UITabBar owned by this view;
/// mode .controller is a child UITabBarController, the structure the tweak
/// uses. In both, UIKit draws the platter, the items and the selection lens
/// at their native size; the whole bar is scaled by `groupScale`, and the
/// titles are drawn larger by the same factor so they stay sharp.
@available(iOS 26.0, *)
private final class NativeCategoryGroup: UIView, UITabBarDelegate, UITabBarControllerDelegate,
    UIGestureRecognizerDelegate {

    enum Mode {
        case standalone
        case controller
    }

    var onSelect: ((Int) -> Void)?

    var groupScale: CGFloat = 1 {
        didSet {
            if abs(groupScale - oldValue) > 0.001 {
                glyphsDirty = true
                setNeedsLayout()
            }
        }
    }

    var slotWidth: CGFloat = 76 {
        didSet {
            if abs(slotWidth - oldValue) > 0.01 {
                fittedKey = ""
                setNeedsLayout()
            }
        }
    }

    let mode: Mode
    private let bar: UITabBar
    private let canvas: UIView
    private let controller: UITabBarController?
    private var proxies: [UIViewController] = []
    private var titles: [String] = []
    private(set) var selected = 0
    private var visibleCount = 2
    private var windowStart = 0
    private var keepSingleSelection = true
    private var glyphsDirty = true
    private var fittedKey = ""
    private var platterRect: CGRect = .zero
    private var platterFound = false
    private var refitPasses = 0

    init(mode: Mode, transparentBackground: Bool) {
        self.mode = mode
        switch mode {
        case .standalone:
            let standalone = UITabBar()
            bar = standalone
            canvas = standalone
            controller = nil
        case .controller:
            let tabController = UITabBarController()
            bar = tabController.tabBar
            canvas = tabController.view
            controller = tabController
        }
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = false

        bar.tintColor = .label
        bar.unselectedItemTintColor = .secondaryLabel
        if transparentBackground {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
        }

        if let controller {
            // A controller-managed bar keeps the controller as its delegate.
            controller.delegate = self
            controller.view.backgroundColor = .clear
        } else {
            bar.delegate = self
            addSubview(canvas)
        }

        // Swipe left/right changes the category (needed with one visible slot).
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        left.direction = .left
        left.delegate = self
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        right.direction = .right
        right.delegate = self
        addGestureRecognizer(left)
        addGestureRecognizer(right)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Child controller

    func attach(to parent: UIViewController?) {
        guard let controller else { return }
        if let parent {
            parent.addChild(controller)
            addSubview(canvas)
            controller.didMove(toParent: parent)
        } else {
            addSubview(canvas)
        }
    }

    func detach() {
        if let controller {
            controller.willMove(toParent: nil)
            canvas.removeFromSuperview()
            controller.removeFromParent()
        }
        removeFromSuperview()
    }

    // MARK: Items

    func configure(titles: [String], selected: Int, visibleCount: Int, keepSingleSelection: Bool) {
        self.titles = titles
        self.selected = labClamp(selected, 0, max(0, titles.count - 1))
        self.visibleCount = labClamp(visibleCount, 1, max(1, titles.count))
        self.keepSingleSelection = keepSingleSelection
        glyphsDirty = true
        rebuildItems()
    }

    func showCategory(_ index: Int) {
        guard index >= 0, index < titles.count else { return }
        selected = index
        rebuildItems()
    }

    private func currentItems() -> [UITabBarItem] {
        if controller != nil {
            return proxies.compactMap { $0.tabBarItem }
        }
        return bar.items ?? []
    }

    private func rebuildItems() {
        guard !titles.isEmpty else { return }
        let count = visibleCount
        if selected < windowStart {
            windowStart = selected
        } else if selected >= windowStart + count {
            windowStart = selected - count + 1
        }
        windowStart = labClamp(windowStart, 0, titles.count - count)

        if currentItems().count != count {
            var items: [UITabBarItem] = []
            for local in 0..<count {
                let item = UITabBarItem(title: nil, image: nil, selectedImage: nil)
                item.tag = windowStart + local
                items.append(item)
            }
            if let controller {
                proxies = items.map { item in
                    let proxy = UIViewController()
                    proxy.view.backgroundColor = .clear
                    proxy.tabBarItem = item
                    return proxy
                }
                controller.setViewControllers(proxies, animated: false)
            } else {
                bar.setItems(items, animated: false)
            }
            fittedKey = ""
        }
        glyphsDirty = true
        updateGlyphs()
        applySelection()
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    private func updateGlyphs() {
        guard glyphsDirty else { return }
        let displayScale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
        for (local, item) in currentItems().enumerated() {
            let index = windowStart + local
            guard index < titles.count else { continue }
            let glyph = LabGlass.textGlyph(
                titles[index],
                pointSize: 15,
                layoutScale: groupScale,
                displayScale: displayScale
            )
            item.image = glyph
            item.selectedImage = glyph
            item.tag = index
            item.accessibilityLabel = titles[index]
        }
        glyphsDirty = false
    }

    private func applySelection() {
        let items = currentItems()
        let local = selected - windowStart
        guard local >= 0, local < items.count else { return }
        if let controller {
            // A controller always keeps one selected tab (clearing it raised
            // in the tweak), so this mode always shows the lens.
            if controller.selectedIndex != local {
                controller.selectedIndex = local
            }
        } else if items.count == 1 && !keepSingleSelection {
            bar.selectedItem = nil
        } else {
            bar.selectedItem = items[local]
        }
    }

    // MARK: Geometry

    /// The group's on-screen size: the native platter times groupScale.
    var visualSize: CGSize {
        let rect = platterRect.isEmpty
            ? CGRect(x: 0, y: 0, width: slotWidth * CGFloat(max(1, currentItems().count)), height: 62)
            : platterRect
        return CGSize(width: rect.width * groupScale, height: rect.height * groupScale)
    }

    func fitIfNeeded() {
        let count = max(1, currentItems().count)
        let key = "\(count)|\(Int(slotWidth * 10))|\(window == nil ? 0 : 1)"
        guard key != fittedKey else { return }
        fittedKey = key
        refitPasses = 0
        measure(desiredWidth: slotWidth * CGFloat(count))
    }

    /// Lays the bar out at its native size and widens or narrows it until
    /// UIKit's own platter is `desiredWidth` wide. Nothing inside is resized.
    private func measure(desiredWidth: CGFloat) {
        var width = desiredWidth + 40
        let height: CGFloat
        if controller != nil {
            height = 160
        } else {
            height = max(49, bar.sizeThatFits(CGSize(width: width, height: 160)).height)
        }
        var rect = CGRect.zero
        var found = false
        for _ in 0..<4 {
            canvas.bounds = CGRect(x: 0, y: 0, width: width, height: height)
            canvas.setNeedsLayout()
            canvas.layoutIfNeeded()
            guard let platter = LabGlass.findPlatter(in: canvas) else {
                found = false
                break
            }
            found = true
            rect = platter.convert(platter.bounds, to: canvas)
            let delta = desiredWidth - rect.width
            if abs(delta) < 0.5 {
                break
            }
            width = labClamp(width + delta, desiredWidth, desiredWidth + 200)
        }
        if !found {
            rect = bar.convert(bar.bounds, to: canvas)
        }
        platterRect = rect
        platterFound = found
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        fittedKey = ""
        // Redraw the titles at the screen's real pixel density.
        glyphsDirty = true
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fitIfNeeded()
        updateGlyphs()
        let rect = platterRect.isEmpty ? canvas.bounds : platterRect
        let scale = groupScale
        canvas.transform = CGAffineTransform(scaleX: scale, y: scale)
        canvas.center = CGPoint(
            x: bounds.midX - (rect.midX - canvas.bounds.midX) * scale,
            y: bounds.midY - (rect.midY - canvas.bounds.midY) * scale
        )
        verifyPlatter()
    }

    /// UIKit may lay the bar out again once it is on screen (safe area,
    /// traits). A moved platter is measured again, at most twice.
    private func verifyPlatter() {
        guard platterFound,
              refitPasses < 2,
              let platter = LabGlass.findPlatter(in: canvas)
        else {
            return
        }
        let rect = platter.convert(platter.bounds, to: canvas)
        let moved = abs(rect.width - platterRect.width) > 0.5
            || abs(rect.midX - platterRect.midX) > 0.5
            || abs(rect.midY - platterRect.midY) > 0.5
        guard moved else { return }
        refitPasses += 1
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let count = max(1, self.currentItems().count)
            self.measure(desiredWidth: self.slotWidth * CGFloat(count))
            self.setNeedsLayout()
            self.superview?.setNeedsLayout()
        }
    }

    func diagnostics() -> String {
        let name = mode == .controller ? "标签栏控制器" : "独立标签栏"
        let onScreen = canvas.convert(platterRect, to: nil)
        var text = "分组(\(name)) 原生胶囊 \(labFormat(platterRect.width))×\(labFormat(platterRect.height))"
        text += platterFound ? "" : "（未找到胶囊，按整条栏计算）"
        text += " · 画布 \(labFormat(canvas.bounds.width))×\(labFormat(canvas.bounds.height))"
        text += " · 比例 \(labFormat(groupScale, digits: 2))"
        text += "\n  分组屏幕位置 \(labRect(onScreen)) · 可见 \(currentItems().count) 项"
        return text
    }

    // MARK: Selection

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        userSelected(item.tag)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let local = proxies.firstIndex(where: { $0 === viewController }) else { return }
        userSelected(windowStart + local)
    }

    private func userSelected(_ index: Int) {
        guard index >= 0, index < titles.count else { return }
        selected = index
        onSelect?(index)

        // One visible slot without a selection capsule: UIKit selected the
        // tapped item, so the selection is cleared again once its tap ends.
        if controller == nil && visibleCount == 1 && !keepSingleSelection {
            DispatchQueue.main.async { [weak self] in
                self?.bar.selectedItem = nil
            }
        }

        // The edge item reveals its neighbour after UIKit's lens settles.
        var start = windowStart
        if visibleCount > 1 {
            if index == windowStart + visibleCount - 1 && start + visibleCount < titles.count {
                start += 1
            } else if index == windowStart && start > 0 {
                start -= 1
            }
        }
        guard start != windowStart else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.windowStart = start
            self.rebuildItems()
        }
    }

    @objc private func swipedLeft() {
        swipe(by: 1)
    }

    @objc private func swipedRight() {
        swipe(by: -1)
    }

    private func swipe(by step: Int) {
        let next = selected + step
        guard next >= 0, next < titles.count else { return }
        selected = next
        rebuildItems()
        onSelect?(next)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - Top chrome: left menu button, category group, right search button

@available(iOS 26.0, *)
private final class TopChromeView: UIView {
    var onOpenSettings: (() -> Void)?
    var onSearch: (() -> Void)?
    weak var hostController: UIViewController?

    let categories = ["直播", "精选", "热点", "兰州", "团购", "经验", "商城", "关注", "推荐"]
    private(set) var selected = 8

    private var navigationBar: PassThroughNavigationBar?
    private var navigationItemRef: UINavigationItem?
    private var group: NativeCategoryGroup?
    private var leftCircle: GlassCircle?
    private var rightCircle: GlassCircle?
    private var groupImpl = 0
    private var sideImpl = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }

    // MARK: Build

    func rebuild() {
        teardown()
        groupImpl = LabSettings.groupImpl
        // The center item group lives in the navigation bar, so its side
        // buttons are that bar's items.
        sideImpl = groupImpl == 2 ? 0 : LabSettings.sideImpl
        if sideImpl == 0 {
            buildNavigationBar()
        }
        if groupImpl != 2 {
            buildGroup()
        }
        if sideImpl != 0 {
            buildCircles()
        }
        setNeedsLayout()
    }

    /// Side-button size changed: glass buttons are rebuilt at the new real
    /// size; the navigation bar is only scaled again.
    func rebuildSides() {
        guard sideImpl != 0 else {
            setNeedsLayout()
            return
        }
        leftCircle?.removeFromSuperview()
        rightCircle?.removeFromSuperview()
        leftCircle = nil
        rightCircle = nil
        buildCircles()
        setNeedsLayout()
    }

    private func teardown() {
        navigationBar?.removeFromSuperview()
        navigationBar = nil
        navigationItemRef = nil
        group?.detach()
        group = nil
        leftCircle?.removeFromSuperview()
        rightCircle?.removeFromSuperview()
        leftCircle = nil
        rightCircle = nil
    }

    private func buildNavigationBar() {
        let bar = PassThroughNavigationBar()
        bar.tintColor = .label
        if LabSettings.transparentBars {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
        }

        let item = UINavigationItem(title: "")
        let left = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "line.3.horizontal"),
            primaryAction: nil,
            menu: makeMenu()
        )
        left.accessibilityLabel = "菜单"
        let right = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "magnifyingglass"),
            primaryAction: UIAction(image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
                self?.onSearch?()
            },
            menu: nil
        )
        right.accessibilityLabel = "搜索"
        item.leftBarButtonItem = left
        item.rightBarButtonItem = right
        if groupImpl == 2 {
            item.style = .editor
            item.centerItemGroups = [centerGroup()]
        }
        bar.setItems([item], animated: false)
        addSubview(bar)
        navigationBar = bar
        navigationItemRef = item
    }

    private func buildGroup() {
        let mode: NativeCategoryGroup.Mode = groupImpl == 1 ? .controller : .standalone
        let group = NativeCategoryGroup(
            mode: mode,
            transparentBackground: LabSettings.transparentBars
        )
        group.onSelect = { [weak self] index in
            self?.selected = index
        }
        group.groupScale = LabSettings.groupScale
        group.slotWidth = LabSettings.slotWidth
        addSubview(group)
        group.attach(to: hostController)
        group.configure(
            titles: categories,
            selected: selected,
            visibleCount: LabSettings.groupCount,
            keepSingleSelection: LabSettings.keepSingleSelection
        )
        self.group = group
    }

    private func buildCircles() {
        guard let kind = GlassCircle.Kind(rawValue: sideImpl - 1) else { return }
        let scale = LabSettings.sideScale
        let left = GlassCircle(kind: kind, symbol: "line.3.horizontal", pointSize: 17 * scale)
        left.button.menu = makeMenu()
        left.button.showsMenuAsPrimaryAction = true
        left.button.accessibilityLabel = "菜单"
        let right = GlassCircle(kind: kind, symbol: "magnifyingglass", pointSize: 17 * scale)
        right.button.addAction(UIAction { [weak self] _ in
            self?.onSearch?()
        }, for: .primaryActionTriggered)
        right.button.accessibilityLabel = "搜索"
        addSubview(left)
        addSubview(right)
        leftCircle = left
        rightCircle = right
    }

    private func centerGroup() -> UIBarButtonItemGroup {
        let count = labClamp(LabSettings.groupCount, 1, categories.count)
        let start = labClamp(selected - count + 1, 0, categories.count - count)
        var items: [UIBarButtonItem] = []
        for index in start..<(start + count) {
            let title = categories[index]
            let item = UIBarButtonItem(
                title: title,
                image: nil,
                primaryAction: UIAction(title: title) { [weak self] _ in
                    self?.selectCategory(index)
                },
                menu: nil
            )
            let isSelected = index == selected
            item.isSelected = isSelected
            item.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 15, weight: isSelected ? .bold : .medium),
            ], for: .normal)
            items.append(item)
        }
        return UIBarButtonItemGroup(barButtonItems: items, representativeItem: nil)
    }

    // MARK: Menu (the same menu for every left-button variant)

    private func makeMenu() -> UIMenu {
        // Built each time it opens, so the checkmark follows the group.
        let categoriesElement = UIDeferredMenuElement.uncached { [weak self] completion in
            completion(self?.categoryMenuElements() ?? [])
        }
        let settings = UIAction(
            title: "实验设置",
            image: UIImage(systemName: "slider.horizontal.3")
        ) { [weak self] _ in
            self?.onOpenSettings?()
        }
        return UIMenu(title: "", children: [categoriesElement, settings])
    }

    private func categoryMenuElements() -> [UIMenuElement] {
        var actions: [UIMenuElement] = []
        for (index, title) in categories.enumerated() {
            actions.append(UIAction(
                title: title,
                state: index == selected ? .on : .off
            ) { [weak self] _ in
                self?.selectCategory(index)
            })
        }
        return [UIMenu(title: "", options: .displayInline, children: actions)]
    }

    private func selectCategory(_ index: Int) {
        guard index >= 0, index < categories.count else { return }
        selected = index
        if groupImpl == 2 {
            navigationItemRef?.centerItemGroups = [centerGroup()]
        } else {
            group?.showCategory(index)
        }
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 0 else { return }
        let sideScale = LabSettings.sideScale
        let margin = LabSettings.sideMargin
        let diameter = 44 * sideScale
        var rowMidY: CGFloat = 0
        var rowHeight: CGFloat = 0

        if let bar = navigationBar {
            // The bar keeps UIKit's own item sizes; the whole bar is scaled
            // and made 1/scale as wide, so it still spans the screen.
            let barWidth = width / sideScale
            let inset = margin / sideScale
            let margins = bar.directionalLayoutMargins
            if abs(margins.leading - inset) > 0.01 || abs(margins.trailing - inset) > 0.01 {
                bar.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    top: margins.top,
                    leading: inset,
                    bottom: margins.bottom,
                    trailing: inset
                )
            }
            let barHeight = max(44, bar.sizeThatFits(CGSize(width: barWidth, height: 200)).height)
            bar.bounds = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)
            bar.center = CGPoint(x: width / 2, y: barHeight * sideScale / 2)
            bar.transform = CGAffineTransform(scaleX: sideScale, y: sideScale)
            rowHeight = barHeight * sideScale
            rowMidY = rowHeight / 2
        }

        if let group {
            group.slotWidth = LabSettings.slotWidth
            group.groupScale = LabSettings.groupScale
            group.fitIfNeeded()
            let size = group.visualSize
            if navigationBar == nil {
                rowHeight = max(size.height, diameter)
                rowMidY = rowHeight / 2
            }
            group.frame = CGRect(
                x: (width - size.width) / 2,
                y: rowMidY - size.height / 2,
                width: size.width,
                height: size.height
            )
        }

        if let left = leftCircle, let right = rightCircle {
            if rowHeight == 0 {
                rowHeight = diameter
                rowMidY = diameter / 2
            }
            var leftX = margin
            var rightX = width - margin - diameter
            if LabSettings.nearGroup, let groupFrame = group?.frame {
                let gap = 10 * sideScale
                leftX = groupFrame.minX - gap - diameter
                rightX = groupFrame.maxX + gap
            }
            left.frame = CGRect(x: leftX, y: rowMidY - diameter / 2, width: diameter, height: diameter)
            right.frame = CGRect(x: rightX, y: rowMidY - diameter / 2, width: diameter, height: diameter)
        }
    }

    func diagnostics() -> String {
        let groupNames = ["独立标签栏", "标签栏控制器", "导航栏按钮组"]
        let sideNames = ["导航栏按钮", "玻璃按钮Regular", "玻璃按钮Clear", "玻璃视图Regular", "玻璃视图Clear"]
        var lines = ["顶栏 分组=\(groupNames[groupImpl]) 两侧=\(sideNames[sideImpl])"]
        if let bar = navigationBar {
            lines.append(
                "导航栏 原生 \(labFormat(bar.bounds.width))×\(labFormat(bar.bounds.height))"
                + " · 比例 \(labFormat(LabSettings.sideScale, digits: 2))"
                + " · 屏幕 \(labRect(bar.convert(bar.bounds, to: nil)))"
            )
            for (number, control) in LabGlass.controls(in: bar).enumerated() {
                lines.append("  栏按钮\(number + 1) \(labRect(control.convert(control.bounds, to: nil)))")
            }
        }
        if let group {
            lines.append(group.diagnostics())
        }
        if let left = leftCircle, let right = rightCircle {
            lines.append("左圆钮 \(labRect(left.convert(left.bounds, to: nil)))")
            lines.append("右圆钮 \(labRect(right.convert(right.bounds, to: nil)))")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Right action column (avatar, like, comment, favorite, share, music)

@available(iOS 26.0, *)
private final class ActionColumnView: UIView {
    private struct Spec {
        let symbol: String
        let count: String?
        let diameter: CGFloat
        let pointSize: CGFloat
    }

    private var circles: [any LabCircle] = []
    private var labels: [UILabel?] = []
    private var diameters: [CGFloat] = []
    private let badge = UIImageView()
    private var liked = false
    private var likeCount = 1064

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        badge.image = UIImage(systemName: "plus.circle.fill")
        badge.tintColor = .systemRed
        badge.backgroundColor = .white
        badge.clipsToBounds = true
        badge.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }

    /// Every button is built at its real size (no transform), so icons stay
    /// sharp and the glass press is UIKit's own at every scale.
    func rebuild() {
        circles.forEach { $0.removeFromSuperview() }
        labels.forEach { $0?.removeFromSuperview() }
        badge.removeFromSuperview()
        circles = []
        labels = []
        diameters = []

        let kind = GlassCircle.Kind(rawValue: LabSettings.rightMaterial)
        let scale = LabSettings.rightScale
        let specs = [
            Spec(symbol: "person.crop.circle.fill", count: nil, diameter: 52, pointSize: 30),
            Spec(symbol: "heart.fill", count: "\(likeCount)", diameter: 48, pointSize: 21),
            Spec(symbol: "ellipsis.bubble.fill", count: "8", diameter: 48, pointSize: 20),
            Spec(symbol: "star.fill", count: "47", diameter: 48, pointSize: 20),
            Spec(symbol: "arrowshape.turn.up.right.fill", count: "12", diameter: 48, pointSize: 20),
            Spec(symbol: "music.note", count: nil, diameter: 46, pointSize: 18),
        ]

        for (index, spec) in specs.enumerated() {
            let tint: UIColor = (index == 1 && liked) ? .systemRed : .label
            let action: (() -> Void)? = index == 1 ? { [weak self] in self?.toggleLike() } : nil
            let circle: any LabCircle
            if let kind {
                let glass = GlassCircle(
                    kind: kind,
                    symbol: spec.symbol,
                    pointSize: spec.pointSize * scale,
                    tint: tint
                )
                if let action {
                    glass.button.addAction(UIAction { _ in action() }, for: .primaryActionTriggered)
                }
                circle = glass
            } else {
                circle = BarGlassCircle(
                    symbol: spec.symbol,
                    pointSize: spec.pointSize * scale,
                    tint: tint,
                    action: action
                )
            }
            addSubview(circle)
            circles.append(circle)
            diameters.append(spec.diameter * scale)

            if let count = spec.count {
                let label = UILabel()
                label.text = count
                label.font = .systemFont(ofSize: 12 * scale, weight: .semibold)
                label.textColor = .white
                label.textAlignment = .center
                label.layer.shadowColor = UIColor.black.cgColor
                label.layer.shadowOpacity = 0.35
                label.layer.shadowRadius = 2
                label.layer.shadowOffset = .zero
                addSubview(label)
                labels.append(label)
            } else {
                labels.append(nil)
            }
        }
        addSubview(badge)
        setNeedsLayout()
    }

    func relayout() {
        setNeedsLayout()
    }

    var preferredSize: CGSize {
        let scale = LabSettings.rightScale
        let spacing = LabSettings.rightSpacing * scale
        var height: CGFloat = 0
        for index in 0..<circles.count {
            height += diameters[index]
            if labels[index] != nil {
                height += 18 * scale
            }
            if index < circles.count - 1 {
                height += spacing
            }
        }
        return CGSize(width: 72 * scale, height: height + 8 * scale)
    }

    private func toggleLike() {
        liked.toggle()
        likeCount += liked ? 1 : -1
        if circles.count > 1 {
            circles[1].setTint(liked ? .systemRed : .label)
        }
        if labels.count > 1 {
            labels[1]?.text = "\(likeCount)"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = LabSettings.rightScale
        let spacing = LabSettings.rightSpacing * scale
        var y: CGFloat = 0
        for index in 0..<circles.count {
            let diameter = diameters[index]
            circles[index].frame = CGRect(
                x: (bounds.width - diameter) / 2,
                y: y,
                width: diameter,
                height: diameter
            )
            if index == 0 {
                let side = 18 * scale
                badge.frame = CGRect(
                    x: bounds.width / 2 - side / 2,
                    y: y + diameter - side / 2,
                    width: side,
                    height: side
                )
                badge.layer.cornerRadius = side / 2
            }
            y += diameter
            if let label = labels[index] {
                label.frame = CGRect(x: 0, y: y + 2 * scale, width: bounds.width, height: 16 * scale)
                y += 18 * scale
            }
            y += spacing
        }
    }

    func diagnostics() -> String {
        var text = "右侧按钮 屏幕 \(labRect(convert(bounds, to: nil)))"
        if let first = circles.first, circles.count > 1 {
            text += " · 头像直径 \(labFormat(first.bounds.width)) · 按钮直径 \(labFormat(circles[1].bounds.width))"
        }
        return text
    }
}

// MARK: - Video feed

@available(iOS 26.0, *)
private final class FeedCell: UICollectionViewCell {
    static let reuseIdentifier = "FeedCell"

    private static let pages: [(name: String, colors: [UIColor], symbol: String)] = [
        ("亮灰", [UIColor(white: 0.94, alpha: 1), UIColor(white: 0.78, alpha: 1)], "person.crop.rectangle"),
        ("粉橙", [UIColor.systemPink, UIColor.systemOrange], "sun.max.fill"),
        ("深蓝", [UIColor(red: 0.05, green: 0.07, blue: 0.16, alpha: 1), UIColor.black], "moon.stars.fill"),
        ("青蓝", [UIColor.systemTeal, UIColor.systemBlue], "water.waves"),
        ("奶白", [UIColor(white: 0.99, alpha: 1), UIColor(red: 0.95, green: 0.90, blue: 0.84, alpha: 1)], "cup.and.saucer.fill"),
        ("紫黑", [UIColor.systemPurple, UIColor.black], "sparkles"),
        ("黄绿", [UIColor.systemYellow, UIColor.systemGreen], "leaf.fill"),
        ("纯黑", [UIColor.black, UIColor(white: 0.18, alpha: 1)], "film.fill"),
    ]

    private let gradientLayer = CAGradientLayer()
    private let symbolView = UIImageView()
    private let authorLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.addSublayer(gradientLayer)
        contentView.clipsToBounds = true

        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = UIColor.white.withAlphaComponent(0.55)
        contentView.addSubview(symbolView)

        for label in [authorLabel, captionLabel] {
            label.textColor = .white
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOpacity = 0.4
            label.layer.shadowRadius = 3
            label.layer.shadowOffset = .zero
            contentView.addSubview(label)
        }
        authorLabel.font = .systemFont(ofSize: 17, weight: .bold)
        captionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        captionLabel.numberOfLines = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = contentView.bounds
        CATransaction.commit()
        let side = bounds.width * 0.42
        symbolView.frame = CGRect(
            x: (bounds.width - side) / 2,
            y: bounds.height * 0.32,
            width: side,
            height: side
        )
        authorLabel.frame = CGRect(x: 16, y: bounds.height - 210, width: bounds.width - 110, height: 24)
        captionLabel.frame = CGRect(x: 16, y: bounds.height - 182, width: bounds.width - 110, height: 44)
    }

    func configure(page: Int) {
        let entry = Self.pages[page % Self.pages.count]
        gradientLayer.colors = entry.colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        symbolView.image = UIImage(systemName: entry.symbol)
        authorLabel.text = "@实验视频 \(page + 1)"
        captionLabel.text = "第 \(page + 1) 条 · 背景：\(entry.name)。长按画面或左上角菜单 → 实验设置"
    }
}

// MARK: - Douyin-like home

@available(iOS 26.0, *)
private final class DouyinHomeViewController: UIViewController, UICollectionViewDataSource {
    private var feed: UICollectionView!
    private let topChrome = TopChromeView()
    private let actions = ActionColumnView()
    private var edgeInteraction: UIInteraction?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        if !view.bounds.isEmpty {
            layout.itemSize = view.bounds.size
        }

        feed = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        feed.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        feed.backgroundColor = .black
        feed.isPagingEnabled = true
        feed.showsVerticalScrollIndicator = false
        feed.contentInsetAdjustmentBehavior = .never
        feed.dataSource = self
        feed.register(FeedCell.self, forCellWithReuseIdentifier: FeedCell.reuseIdentifier)
        view.addSubview(feed)
        // The native bottom bar reads this scroll view (minimize on scroll).
        setContentScrollView(feed, for: .bottom)

        view.addSubview(actions)
        view.addSubview(topChrome)

        topChrome.hostController = self
        topChrome.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        topChrome.onSearch = { [weak self] in
            guard let controller = self?.tabBarController,
                  let search = controller.tabs.last
            else {
                return
            }
            controller.selectedTab = search
        }

        let press = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        press.minimumPressDuration = 0.6
        feed.addGestureRecognizer(press)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged(_:)),
            name: LabSettings.didChange,
            object: nil
        )
        recoverFromCrashedRebuildIfNeeded()
        applyAll()

        // The right column's glass buttons keep the light/dark look they were
        // built with; the bars follow a later style change, these do not. So
        // rebuild them whenever the style changes (setting or system).
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.actions.rebuild()
            self.view.setNeedsLayout()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBottomMinimize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyAppearance()
        topChrome.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = feed.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize != view.bounds.size {
            layout.itemSize = view.bounds.size
            layout.invalidateLayout()
        }

        let insets = view.safeAreaInsets
        topChrome.frame = CGRect(x: 0, y: insets.top, width: view.bounds.width, height: 120)

        let size = actions.preferredSize
        actions.frame = CGRect(
            x: view.bounds.width - size.width - LabSettings.rightMargin,
            y: view.bounds.height - insets.bottom - LabSettings.rightBottom - size.height,
            width: size.width,
            height: size.height
        )
    }

    // MARK: Settings

    @objc private func settingsChanged(_ notification: Notification) {
        let key = notification.userInfo?[LabSettings.changedKey] as? String ?? ""
        switch key {
        case LabKey.groupScale, LabKey.slotWidth, LabKey.sideMargin, LabKey.nearGroup:
            topChrome.setNeedsLayout()
        case LabKey.sideScale:
            topChrome.rebuildSides()
        case LabKey.rightSpacing, LabKey.rightMargin, LabKey.rightBottom:
            actions.relayout()
            view.setNeedsLayout()
        case LabKey.rightMaterial, LabKey.rightScale:
            actions.rebuild()
            view.setNeedsLayout()
        case LabKey.edgeEffect:
            applyEdgeEffect()
        case LabKey.bottomMinimize:
            applyBottomMinimize()
        case LabKey.appearance:
            applyAppearance()
        default:
            applyAll()
        }
    }

    /// A structural change that crashes would otherwise crash every launch
    /// (the settings persist). The flag is cleared 3 s after a rebuild; if it
    /// is still set at launch, the previous rebuild never survived, and the
    /// lab starts from the defaults.
    private static let pendingKey = "lab.rebuild.pending"

    private func recoverFromCrashedRebuildIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.pendingKey) else { return }
        for key in LabKey.all {
            defaults.removeObject(forKey: key)
        }
        defaults.set(false, forKey: Self.pendingKey)
    }

    private func applyAll() {
        UserDefaults.standard.set(true, forKey: Self.pendingKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UserDefaults.standard.set(false, forKey: Self.pendingKey)
        }
        topChrome.rebuild()
        actions.rebuild()
        applyEdgeEffect()
        applyBottomMinimize()
        applyAppearance()
        view.setNeedsLayout()
    }

    private func applyEdgeEffect() {
        let mode = LabSettings.edgeEffect
        LabGlass.configureTopEdgeEffect(feed, mode: mode)
        if mode == 0 {
            if let edgeInteraction {
                topChrome.removeInteraction(edgeInteraction)
            }
            edgeInteraction = nil
        } else if edgeInteraction == nil,
                  let interaction = LabGlass.makeTopEdgeContainerInteraction(for: feed) {
            topChrome.addInteraction(interaction)
            edgeInteraction = interaction
        }
    }

    private func applyBottomMinimize() {
        tabBarController?.tabBarMinimizeBehavior = LabSettings.bottomMinimize ? .onScrollDown : .never
    }

    private func applyAppearance() {
        let style: UIUserInterfaceStyle
        switch LabSettings.appearance {
        case 1:
            style = .dark
        case 2:
            style = .light
        default:
            style = .unspecified
        }
        view.window?.overrideUserInterfaceStyle = style
    }

    private func diagnosticsText() -> String {
        let insets = view.safeAreaInsets
        var lines = [
            "LiquidGlassLab 0.4.0 · 屏幕 \(labFormat(view.bounds.width))×\(labFormat(view.bounds.height))"
            + " · 安全区 上\(labFormat(insets.top)) 下\(labFormat(insets.bottom))",
        ]
        lines.append(topChrome.diagnostics())
        lines.append(actions.diagnostics())
        return lines.joined(separator: "\n")
    }

    @objc private func longPressed(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            openSettings()
        }
    }

    private func openSettings() {
        guard presentedViewController == nil else { return }
        let controller = LabSettingsViewController()
        controller.diagnosticsProvider = { [weak self] in
            self?.diagnosticsText() ?? ""
        }
        if let sheet = controller.sheetPresentationController {
            let small = UISheetPresentationController.Detent.custom(
                identifier: UISheetPresentationController.Detent.Identifier(rawValue: "lab.small")
            ) { context in
                context.maximumDetentValue * 0.34
            }
            sheet.detents = [small, .medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .medium
        }
        present(controller, animated: true)
    }

    // MARK: Feed data

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        80
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeedCell.reuseIdentifier,
            for: indexPath
        ) as? FeedCell else {
            return UICollectionViewCell()
        }
        cell.configure(page: indexPath.item)
        return cell
    }
}

// MARK: - Settings sheet (live; the home stays usable above the sheet)

@available(iOS 26.0, *)
private final class LabSettingsViewController: UIViewController {
    var diagnosticsProvider: (() -> String)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let diagnosticsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
        ])

        buildRows()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: LabSettings.didChange,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshDiagnostics()
    }

    @objc private func settingsChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.refreshDiagnostics()
        }
    }

    private func refreshDiagnostics() {
        diagnosticsLabel.text = diagnosticsProvider?() ?? ""
    }

    private func buildRows() {
        stack.addArrangedSubview(header("LiquidGlassLab 0.4.0 · 实验设置"))

        diagnosticsLabel.numberOfLines = 0
        diagnosticsLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        diagnosticsLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(diagnosticsLabel)

        var copyConfiguration = UIButton.Configuration.glass()
        copyConfiguration.title = "复制测量信息"
        let copy = UIButton(configuration: copyConfiguration)
        copy.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.refreshDiagnostics()
            UIPasteboard.general.string = self.diagnosticsLabel.text
        }, for: .primaryActionTriggered)
        stack.addArrangedSubview(copy)

        stack.addArrangedSubview(header("顶部分组"))
        stack.addArrangedSubview(segmentRow(
            "分组实现",
            items: ["独立标签栏", "标签栏控制器", "导航栏按钮组"],
            selected: LabSettings.groupImpl
        ) { LabSettings.store($0, LabKey.groupImpl) })
        stack.addArrangedSubview(segmentRow(
            "分组数量",
            items: ["1", "2", "3", "4"],
            selected: LabSettings.groupCount - 1
        ) { LabSettings.store($0 + 1, LabKey.groupCount) })
        stack.addArrangedSubview(switchRow(
            "一个分类时保留选中胶囊（独立标签栏）",
            value: LabSettings.keepSingleSelection
        ) { LabSettings.store($0, LabKey.keepSingle) })
        stack.addArrangedSubview(sliderRow(
            "分组比例（整条原生栏缩放）",
            value: Double(LabSettings.groupScale),
            range: 0.5...1.2
        ) { LabSettings.store($0, LabKey.groupScale) })
        stack.addArrangedSubview(sliderRow(
            "分组单项宽度（原生尺寸）",
            value: Double(LabSettings.slotWidth),
            range: 44...120
        ) { LabSettings.store($0, LabKey.slotWidth) })

        stack.addArrangedSubview(header("分组左右按钮"))
        stack.addArrangedSubview(segmentRow(
            "按钮实现",
            items: ["导航栏", "按钮R", "按钮C", "视图R", "视图C"],
            selected: LabSettings.sideImpl
        ) { LabSettings.store($0, LabKey.sideImpl) })
        stack.addArrangedSubview(sliderRow(
            "按钮比例",
            value: Double(LabSettings.sideScale),
            range: 0.6...1.3
        ) { LabSettings.store($0, LabKey.sideScale) })
        stack.addArrangedSubview(sliderRow(
            "按钮边距",
            value: Double(LabSettings.sideMargin),
            range: 0...40
        ) { LabSettings.store($0, LabKey.sideMargin) })
        stack.addArrangedSubview(switchRow(
            "按钮靠近分组（玻璃按钮/玻璃视图）",
            value: LabSettings.nearGroup
        ) { LabSettings.store($0, LabKey.nearGroup) })

        stack.addArrangedSubview(header("顶部背景"))
        stack.addArrangedSubview(segmentRow(
            "顶部边缘效果",
            items: ["隐藏", "自动", "软", "硬"],
            selected: LabSettings.edgeEffect
        ) { LabSettings.store($0, LabKey.edgeEffect) })
        stack.addArrangedSubview(switchRow(
            "栏使用透明外观（插件不建议）",
            value: LabSettings.transparentBars
        ) { LabSettings.store($0, LabKey.transparentBars) })

        stack.addArrangedSubview(header("右侧按钮"))
        stack.addArrangedSubview(segmentRow(
            "材质",
            items: ["按钮R", "按钮C", "视图R", "视图C", "栏按钮"],
            selected: LabSettings.rightMaterial
        ) { LabSettings.store($0, LabKey.rightMaterial) })
        stack.addArrangedSubview(sliderRow(
            "整体缩放（真实尺寸）",
            value: Double(LabSettings.rightScale),
            range: 0.6...1.3
        ) { LabSettings.store($0, LabKey.rightScale) })
        stack.addArrangedSubview(sliderRow(
            "按钮间距",
            value: Double(LabSettings.rightSpacing),
            range: 0...30
        ) { LabSettings.store($0, LabKey.rightSpacing) })
        stack.addArrangedSubview(sliderRow(
            "右边距",
            value: Double(LabSettings.rightMargin),
            range: 0...40
        ) { LabSettings.store($0, LabKey.rightMargin) })
        stack.addArrangedSubview(sliderRow(
            "距底栏",
            value: Double(LabSettings.rightBottom),
            range: 0...200
        ) { LabSettings.store($0, LabKey.rightBottom) })

        stack.addArrangedSubview(header("底栏与外观"))
        stack.addArrangedSubview(switchRow(
            "底栏随滑动缩小",
            value: LabSettings.bottomMinimize
        ) { LabSettings.store($0, LabKey.bottomMinimize) })
        stack.addArrangedSubview(segmentRow(
            "深浅色",
            items: ["跟随系统", "深色", "浅色"],
            selected: LabSettings.appearance
        ) { LabSettings.store($0, LabKey.appearance) })

        var resetConfiguration = UIButton.Configuration.glass()
        resetConfiguration.title = "恢复默认"
        let reset = UIButton(configuration: resetConfiguration)
        reset.addAction(UIAction { [weak self] _ in
            LabSettings.reset()
            self?.dismiss(animated: true)
        }, for: .primaryActionTriggered)
        stack.addArrangedSubview(reset)

        let note = UILabel()
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabel
        note.text = """
        分组：独立标签栏 = 自己持有的 UITabBar；标签栏控制器 = 子 UITabBarController（插件现在的结构）；导航栏按钮组 = 导航栏中间按钮组（此时左右键固定用导航栏按钮）。前两种由 UIKit 按原生尺寸画胶囊和选中透镜，“分组比例”整体缩放，文字按比例放大绘制保持清晰。
        左右按钮：导航栏 = 系统导航栏按钮（栏玻璃，与底栏同一类，原生展开菜单与按压形变），按钮比例为整条栏缩放；按钮R/C = 系统玻璃按钮；视图R/C = 交互式玻璃视图 + 普通按钮。玻璃按钮和玻璃视图按真实尺寸缩放。
        顶部边缘效果：除“隐藏”外会把顶栏登记为视频流的顶部边缘元素，由系统在顶栏后面画一整块边缘效果。
        右侧按钮全部按真实尺寸缩放。所有改动即时生效，可停在小/中半屏对照；上方测量信息可复制后发回。
        """
        stack.addArrangedSubview(note)
    }

    private func header(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        return label
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    private func segmentRow(
        _ title: String,
        items: [String],
        selected: Int,
        onChange: @escaping (Int) -> Void
    ) -> UIView {
        let control = UISegmentedControl(items: items)
        control.apportionsSegmentWidthsByContent = true
        control.selectedSegmentIndex = selected
        control.addAction(UIAction { [weak control] _ in
            guard let control else { return }
            onChange(control.selectedSegmentIndex)
        }, for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [caption(title), control])
        row.axis = .vertical
        row.spacing = 6
        return row
    }

    private func sliderRow(
        _ title: String,
        value: Double,
        range: ClosedRange<Double>,
        onChange: @escaping (Double) -> Void
    ) -> UIView {
        let valueLabel = UILabel()
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valueLabel.textColor = .secondaryLabel
        valueLabel.text = String(format: "%.2f", value)

        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.addAction(UIAction { [weak slider, weak valueLabel] _ in
            guard let slider else { return }
            valueLabel?.text = String(format: "%.2f", Double(slider.value))
            onChange(Double(slider.value))
        }, for: .valueChanged)

        let top = UIStackView(arrangedSubviews: [caption(title), valueLabel])
        top.axis = .horizontal
        top.distribution = .equalSpacing
        let row = UIStackView(arrangedSubviews: [top, slider])
        row.axis = .vertical
        row.spacing = 4
        return row
    }

    private func switchRow(
        _ title: String,
        value: Bool,
        onChange: @escaping (Bool) -> Void
    ) -> UIView {
        let toggle = UISwitch()
        toggle.isOn = value
        toggle.addAction(UIAction { [weak toggle] _ in
            onChange(toggle?.isOn ?? false)
        }, for: .valueChanged)
        let row = UIStackView(arrangedSubviews: [caption(title), toggle])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }
}

// MARK: - Other tabs (0.3.4 baseline)

@available(iOS 26.0, *)
private final class PhotosGridViewController: UICollectionViewController {
    enum Kind {
        case library
        case featured
        case albums
        case shared

        var title: String {
            switch self {
            case .library:
                return "图库"
            case .featured:
                return "精选集"
            case .albums:
                return "相簿"
            case .shared:
                return "共享"
            }
        }

        var subtitle: String {
            switch self {
            case .library:
                return "58,903 个项目"
            case .featured:
                return "系统标签页"
            case .albums:
                return "新增标签测试一"
            case .shared:
                return "新增标签测试二"
            }
        }

        var itemCount: Int {
            switch self {
            case .library:
                return 120
            case .featured:
                return 60
            case .albums:
                return 72
            case .shared:
                return 48
            }
        }

        var itemOffset: Int {
            switch self {
            case .library:
                return 0
            case .featured:
                return 100
            case .albums:
                return 200
            case .shared:
                return 300
            }
        }

        var columns: Int {
            switch self {
            case .library:
                return 5
            case .featured, .albums, .shared:
                return 2
            }
        }

        var spacing: CGFloat {
            self == .library ? 1 : 10
        }
    }

    private let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        super.init(collectionViewLayout: Self.makeLayout(kind: kind))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .black
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.register(
            PhotoGridCell.self,
            forCellWithReuseIdentifier: PhotoGridCell.reuseIdentifier
        )

        title = kind.title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: "选择",
                style: .plain,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal"),
                style: .plain,
                target: nil,
                action: nil
            ),
        ]

        navigationItem.subtitle = kind.subtitle
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        kind.itemCount
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoGridCell.reuseIdentifier,
            for: indexPath
        ) as? PhotoGridCell else {
            return UICollectionViewCell()
        }

        cell.configure(index: indexPath.item + kind.itemOffset)
        return cell
    }

    private static func makeLayout(
        kind: Kind
    ) -> UICollectionViewLayout {
        let columns = kind.columns
        let spacing = kind.spacing
        let fraction = 1.0 / CGFloat(columns)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(fraction),
            heightDimension: .fractionalWidth(fraction)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(fraction)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: columns
        )
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        if kind != .library {
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 10,
                leading: 10,
                bottom: 10,
                trailing: 10
            )
        }

        return UICollectionViewCompositionalLayout(section: section)
    }
}

@available(iOS 26.0, *)
private final class PhotoGridCell: UICollectionViewCell {
    static let reuseIdentifier = "PhotoGridCell"

    private let gradientLayer = CAGradientLayer()
    private let imageView = UIImageView()
    private let durationLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.addSublayer(gradientLayer)
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.white.withAlphaComponent(0.66)
        contentView.addSubview(imageView)

        durationLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .right
        contentView.addSubview(durationLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        imageView.frame = contentView.bounds.insetBy(
            dx: bounds.width * 0.34,
            dy: bounds.height * 0.34
        )
        durationLabel.frame = CGRect(
            x: 4,
            y: bounds.height - 18,
            width: bounds.width - 8,
            height: 14
        )
    }

    func configure(index: Int) {
        let palettes: [[UIColor]] = [
            [.systemIndigo, .black, .systemCyan],
            [.systemRed, .systemPink, .systemOrange],
            [.systemTeal, .systemBlue, .black],
            [.systemPurple, .systemRed, .black],
            [
                .systemGray,
                .black,
                UIColor.white.withAlphaComponent(0.45),
            ],
            [.systemGreen, .systemMint, .black],
        ]
        let symbols = [
            "person.crop.rectangle",
            "mountain.2.fill",
            "photo.on.rectangle",
            "video.fill",
            "building.2.fill",
            "figure.walk",
            "camera.fill",
            "sun.max.fill",
            "water.waves",
            "leaf.fill",
        ]

        let colors = palettes[index % palettes.count]
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = index.isMultiple(of: 2)
            ? CGPoint(x: 0, y: 0)
            : CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = index.isMultiple(of: 3)
            ? CGPoint(x: 1, y: 1)
            : CGPoint(x: 1, y: 0)

        imageView.image = UIImage(
            systemName: symbols[index % symbols.count]
        )
        durationLabel.text = index.isMultiple(of: 9)
            ? String(format: "0:%02d", (index * 3) % 59)
            : nil
    }
}

@available(iOS 26.0, *)
private final class PhotosSearchViewController: UIViewController,
    UISearchResultsUpdating {

    private let label = UILabel()
    private let searchController = UISearchController(
        searchResultsController: nil
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        title = "搜索"

        label.text = "搜索照片"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            label.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
        ])

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索照片"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    func updateSearchResults(
        for searchController: UISearchController
    ) {
        let text = searchController.searchBar.text ?? ""
        label.text = text.isEmpty ? "搜索照片" : "搜索：\(text)"
    }
}
