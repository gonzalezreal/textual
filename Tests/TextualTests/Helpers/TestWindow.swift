#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import UIKit

  /// Hosts a view controller in a visible window, so it updates and lays out the way it does on
  /// screen.
  @MainActor
  final class TestWindow<RootViewController: UIViewController> {
    let rootViewController: RootViewController
    private let window: UIWindow

    init(_ rootViewController: RootViewController, size: CGSize = CGSize(width: 390, height: 844)) {
      self.rootViewController = rootViewController
      self.window = UIWindow(frame: CGRect(origin: .zero, size: size))
      self.window.rootViewController = rootViewController
      self.window.isHidden = false
      settle()
    }

    deinit {
      let window = window
      MainActor.assumeIsolated {
        window.isHidden = true
      }
    }

    /// Runs pending updates, such as state changes and preference changes, and lays out again.
    func settle() {
      for _ in 0..<4 {
        while CFRunLoopRunInMode(.defaultMode, 0, true) == .handledSource {}
        rootViewController.view.setNeedsLayout()
        rootViewController.view.layoutIfNeeded()
      }
    }

    /// The first scroll view in the hierarchy, such as the collection view behind a `List`.
    var scrollView: UIScrollView? {
      Self.firstScrollView(in: rootViewController.view)
    }

    private static func firstScrollView(in view: UIView) -> UIScrollView? {
      if let scrollView = view as? UIScrollView {
        return scrollView
      }
      return view.subviews.lazy.compactMap(firstScrollView(in:)).first
    }
  }

  extension TestWindow {
    convenience init<Content: View>(_ content: Content)
    where RootViewController == UIHostingController<Content> {
      self.init(UIHostingController(rootView: content))
    }
  }
#endif
