import Cocoa

extension Delegate: NSCollectionViewDelegate {

  public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    /*
     This delay is here to avoid an assertion that happens inside the collection view binding,
     it tries to resolve the item at index but it no longer exists so the assertion is thrown.
     This can probably be fixed in a more convenient way in the future without delays.
     */
    Dispatch.after(seconds: 0.1) { [weak self] in
      guard let strongSelf = self, let first = indexPaths.first,
        let component = strongSelf.component,
        let item = component.item(at: first.item), first.item < component.items.count else {
          return
      }
      component.delegate?.component(component, itemSelected: item)
    }
  }

  /// Notifies the delegate that the specified item is about to be displayed by the collection view.
  ///
  /// - parameter collectionView: The collection view that is adding the item.
  /// - parameter item: The item being added.
  /// - parameter indexPath: The index path of the item.
  public func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    let view = item

    guard
      let component = component,
      let item = component.item(at: indexPath)
      else {
        return
    }

    component.delegate?.component(component, willDisplay: view, item: item)
  }

  /// Notifies the delegate that the specified item was removed from the collection view.
  ///
  /// - parameter collectionView: The collection view that removed the item.
  /// - parameter item: The item that was removed.
  /// - parameter indexPath: The index path of the item.
  public func collectionView(_ collectionView: NSCollectionView, didEndDisplaying item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
    let view = item

    guard
      let component = component,
      let item = component.item(at: indexPath)
      else {
        return
    }

    component.delegate?.component(component, didEndDisplaying: view, item: item)
  }
}

extension Delegate: NSCollectionViewDelegateFlowLayout {

  public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    guard let component = component else {
      return CGSize.zero
    }
    return component.sizeForItem(at: indexPath)
  }
}

extension Delegate: NSTableViewDelegate {

  public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    guard let component = component,
      let item = component.item(at: row),
      row > -1 && row < component.model.items.count
      else {
        return false
    }

    if component.model.meta(ListComponent.Key.doubleAction, type: Bool.self) != true {
      component.delegate?.component(component, itemSelected: item)
    }

    return true
  }

  public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    guard let component = component else {
      return 1.0
    }

    component.model.size = CGSize(
      width: tableView.frame.width,
      height: tableView.frame.height)

    let height = row < component.model.items.count
      ? component.item(at: row)?.size.height ?? 0
      : 1.0

    if height == 0 {
      return 1.0
    }

    return height
  }

  public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    guard let component = component, row >= 0 && row < component.model.items.count else {
      return nil
    }

    let reuseIdentifier = component.identifier(at: row)
    var craftedView = component.type.views.make(reuseIdentifier)

    if craftedView == nil {
      craftedView = Configuration.views.make(reuseIdentifier)
    }

    guard let cachedView = craftedView else {
      return nil
    }

    var resolvedView: View? = nil
    if let type = cachedView.type {
      switch type {
      case .regular:
        resolvedView = cachedView.view
      case .nib:
        resolvedView = tableView.make(withIdentifier: reuseIdentifier, owner: nil)
      }
    }

    switch resolvedView {
    case let view as Composable:
      let components = component.compositeComponents.filter { $0.itemIndex == row }
      view.contentView.frame.size.width = tableView.frame.size.width
      view.contentView.frame.size.height = component.computedHeight
      view.configure(&component.model.items[row], compositeComponents: components)
    case let view as View:
      let customView = view

      if !(view is NSTableRowView) {
        let wrapper = ListWrapper()
        wrapper.configure(with: view)
        resolvedView = wrapper
      }

      (customView as? ItemConfigurable)?.configure(&component.model.items[row])
    case let view as ItemConfigurable:
      view.configure(&component.model.items[row])
    default:
      break
    }

    (resolvedView as? NSTableRowView)?.identifier = reuseIdentifier

    return resolvedView as? NSTableRowView
  }

  public func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
    guard
      let component = component,
      let item = component.item(at: row),
      let view = cell as? View
      else {
        return
    }

    component.delegate?.component(component, willDisplay: view, item: item)
  }

  public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    return nil
  }
}
