import Cocoa

extension Component {

  func setupHeader(with configuration: Configuration) {
    guard let header = model.header, headerView == nil else {
      return
    }

    if let headerView = configuration.views.make(header.kind)?.view {
      self.headerView = headerView
      reloadHeader()
      (collectionView?.flowLayout)?.headerReferenceSize = headerView.frame.size
      scrollView.documentView?.addSubview(headerView)
    }
  }

  func setupFooter(with configuration: Configuration) {
    guard let footer = model.footer, footerView == nil else {
      return
    }

    if let footerView = configuration.views.make(footer.kind)?.view {
      self.footerView = footerView
      reloadFooter()
      (collectionView?.flowLayout)?.footerReferenceSize = footerView.frame.size
      scrollView.documentView?.addSubview(footerView)
    }
  }

  func layoutHeaderFooterViews(_ size: CGSize) {
    headerView?.frame.size.width = size.width
    footerView?.frame.size.width = size.width
    footerView?.frame.origin.y = scrollView.frame.height - footerHeight
  }
}
