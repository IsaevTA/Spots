import Cocoa
import Sugar
import Brick
import Hue

public class CarouselSpot: NSObject, Gridable {

  public struct Key {
    public static let minimumInteritemSpacing = "itemSpacing"
    public static let minimumLineSpacing = "lineSpacing"
    public static let titleFontSize = "titleFontSize"
    public static let titleLeftMargin = "titleLeftMargin"
    public static let titleTopInset = "titleTopInset"
    public static let titleBottomInset = "titleBottomInset"
    public static let titleLeftInset = "titleLeftInset"
    public static let titleTextColor = "titleTextColor"
  }

  public struct Default {
    public static var titleFontSize: CGFloat = 18.0
    public static var titleLeftInset: CGFloat = 0.0
    public static var titleTopInset: CGFloat = 10.0
    public static var titleBottomInset: CGFloat = 10.0
    public static var titleTextColor: String = "000000"
    public static var sectionInsetTop: CGFloat = 0.0
    public static var sectionInsetLeft: CGFloat = 0.0
    public static var sectionInsetRight: CGFloat = 0.0
    public static var sectionInsetBottom: CGFloat = 0.0
    public static var minimumInteritemSpacing: CGFloat = 0.0
    public static var minimumLineSpacing: CGFloat = 0.0
  }

  public static var views = ViewRegistry()
  public static var grids = GridRegistry()
  public static var configure: ((view: NSCollectionView) -> Void)?
  public static var defaultGrid: NSCollectionViewItem.Type = NSCollectionViewItem.self
  public static var defaultView: View.Type = NSView.self
  public static var defaultKind: StringConvertible = Component.Kind.Carousel.string

  public weak var spotsDelegate: SpotsDelegate?

  public var cachedViews = [String : SpotConfigurable]()
  public var component: Component
  public var configure: (SpotConfigurable -> Void)?
  public var index = 0

  public private(set) var stateCache: SpotCache?

  public var gradientLayer: CAGradientLayer?

  public lazy var collectionAdapter: CollectionAdapter = CollectionAdapter(spot: self)
  public var adapter: SpotAdapter? {
    return collectionAdapter
  }

  public lazy var layout: NSCollectionViewLayout = NSCollectionViewFlowLayout()

  public lazy var titleView: NSTextField = NSTextField().then {
    $0.editable = false
    $0.selectable = false
    $0.bezeled = false
    $0.drawsBackground = false
    $0.textColor = NSColor.grayColor()
  }

  public lazy var scrollView: ScrollView = ScrollView()

  public lazy var collectionView: NSCollectionView = NSCollectionView().then {
    $0.selectable = true
    $0.backgroundColors = [NSColor.clearColor()]

    let view = NSView()
    $0.backgroundView = view
  }

  lazy var lineView = NSView().then {
    $0.frame.size.height = 1
    $0.wantsLayer = true
    $0.layer?.backgroundColor = NSColor.grayColor().colorWithAlphaComponent(0.2).CGColor
  }

  public required init(component: Component) {
    self.component = component

    super.init()

    setupCollectionView()
    configureLayoutInsets(component)

    if let layout = layout as? NSCollectionViewFlowLayout where component.title.isPresent {
      configureTitleView(layout.sectionInset)
    }
    scrollView.addSubview(titleView)
    scrollView.addSubview(lineView)
    scrollView.documentView = collectionView
  }

  private func configureLayoutInsets(component: Component) {
    guard let layout = layout as? NSCollectionViewFlowLayout else { return }

    layout.sectionInset = NSEdgeInsets(
      top: component.meta(GridableMeta.Key.sectionInsetTop, Default.sectionInsetTop),
      left: component.meta(GridableMeta.Key.sectionInsetLeft, Default.sectionInsetLeft),
      bottom: component.meta(GridableMeta.Key.sectionInsetBottom, Default.sectionInsetBottom),
      right: component.meta(GridableMeta.Key.sectionInsetRight, Default.sectionInsetRight))
    layout.minimumInteritemSpacing = component.meta(Key.minimumInteritemSpacing, Default.minimumInteritemSpacing)
    layout.minimumLineSpacing = component.meta(Key.minimumLineSpacing, Default.minimumLineSpacing)
    layout.scrollDirection = .Horizontal
  }

  public convenience init(cacheKey: String) {
    let stateCache = SpotCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache

    prepare()
  }

  deinit {
    collectionView.delegate = nil
    collectionView.dataSource = nil
  }

  public func setupCollectionView() {
    collectionView.delegate = collectionAdapter
    collectionView.dataSource = collectionAdapter
    collectionView.collectionViewLayout = layout
  }

  public func render() -> ScrollView {
    return scrollView
  }

  public func layout(size: CGSize) {
    var layoutInsets = NSEdgeInsets()

    if let layout = layout as? NSCollectionViewFlowLayout {
      layout.sectionInset.top = component.meta(GridableMeta.Key.sectionInsetTop, Default.sectionInsetTop) + titleView.frame.size.height + 8
      layoutInsets = layout.sectionInset
    }

    scrollView.frame.size.height = (component.items.first?.size.height ?? layoutInsets.top) + layoutInsets.top + layoutInsets.bottom
    collectionView.frame.size.height = scrollView.frame.size.height
    gradientLayer?.frame.size.height = scrollView.frame.size.height

    if component.title.isPresent {
      configureTitleView(layoutInsets)
    }

    if component.span > 0 {
      component.items.enumerate().forEach {
        component.items[$0.index].size.width = size.width / component.span
      }
    }

    if component.span == 1 && component.items.count == 1 {
      scrollView.scrollingEnabled = (component.items.count > 1)
      scrollView.hasHorizontalScroller = (component.items.count > 1)
      component.items.enumerate().forEach {
        component.items[$0.index].size.width = size.width / component.span
      }
      layout.invalidateLayout()
    }
  }

  public func setup(size: CGSize) {
    if component.span > 0 {
      component.items.enumerate().forEach {
        component.items[$0.index].size.width = size.width / component.span
      }
    }

    layout(size)
    CarouselSpot.configure?(view: collectionView)
  }

  private func configureTitleView(layoutInsets: NSEdgeInsets) {
    titleView.stringValue = component.title
    titleView.sizeToFit()
    titleView.font = NSFont.systemFontOfSize(component.meta(Key.titleFontSize, Default.titleFontSize))
    titleView.sizeToFit()
    titleView.frame.size.width = collectionView.frame.width - layoutInsets.right - layoutInsets.left
    lineView.frame.size.width = scrollView.frame.size.width - (component.meta(Key.titleLeftMargin, titleView.frame.origin.x) * 2)
    lineView.frame.origin.x = component.meta(Key.titleLeftMargin, titleView.frame.origin.x)
    titleView.frame.origin.x = collectionView.frame.origin.x + component.meta(Key.titleLeftInset, Default.titleLeftInset)
    titleView.frame.origin.x = component.meta(Key.titleLeftMargin, titleView.frame.origin.x)
    titleView.frame.origin.y = component.meta(Key.titleTopInset, Default.titleTopInset) - component.meta(Key.titleBottomInset, Default.titleBottomInset)
    lineView.frame.origin.y = titleView.frame.maxY + 5
    collectionView.frame.size.height = scrollView.frame.size.height + titleView.frame.size.height
  }
}

extension CarouselSpot {

  public func sizeForItemAt(indexPath: NSIndexPath) -> CGSize {
    var width = component.span > 0
      ? collectionView.frame.width / CGFloat(component.span)
      : collectionView.frame.width

    if let layout = layout as? NSCollectionViewFlowLayout {
      width -= layout.sectionInset.left - layout.sectionInset.right
      width -= layout.minimumInteritemSpacing
      width -= layout.minimumLineSpacing
    }

    if component.items[indexPath.item].size.width == 0.0 {
      component.items[indexPath.item].size.width = width
    }

    return CGSize(
      width: ceil(component.items[indexPath.item].size.width),
      height: ceil(component.items[indexPath.item].size.height))
  }
}