// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

protocol RootViewControllerProvider: class {
    var rootViewController: UIViewController { get }
}

typealias RootCoordinator = Coordinator & RootViewControllerProvider

final class NavigationController: UIViewController {
    private let rootViewController: UIViewController
    private var viewControllersToChildCoordinators: [UIViewController: Coordinator] = [:]

    var viewControllers: [UIViewController] = [] {
        didSet {
            childNavigationController.viewControllers = viewControllers
        }
    }
    var navigationBar: UINavigationBar {
        return childNavigationController.navigationBar
    }

    var isToolbarHidden: Bool {
        get { return childNavigationController.isToolbarHidden }
        set { childNavigationController.isToolbarHidden = newValue }
    }

    let childNavigationController: UINavigationController

    @discardableResult
    static func openFormSheet(
        for controller: UIViewController,
        in navigationController: NavigationController,
        barItem: UIBarButtonItem
    ) -> UIViewController {
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.navigationItem.leftBarButtonItem = barItem
            let nav = NavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .formSheet
            navigationController.present(nav, animated: true, completion: nil)
        } else {
            navigationController.pushViewController(controller, animated: true)
        }
        return controller
    }

    init(rootViewController: UIViewController = UIViewController()) {
        self.rootViewController = rootViewController
        self.childNavigationController = UINavigationController(rootViewController: rootViewController)
        super.init(nibName: nil, bundle: nil)
    }

    init(
        navigationBarClass: Swift.AnyClass?,
        toolbarClass: Swift.AnyClass?
    ) {
        self.rootViewController = UIViewController()
        self.childNavigationController = UINavigationController(
            navigationBarClass: navigationBarClass,
            toolbarClass: toolbarClass
        )
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        childNavigationController.delegate = self
        childNavigationController.interactivePopGestureRecognizer?.delegate = self

        addChildViewController(childNavigationController)
        view.addSubview(childNavigationController.view)
        childNavigationController.didMove(toParentViewController: self)

        childNavigationController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            childNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childNavigationController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            childNavigationController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            childNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Public

    func pushCoordinator(coordinator: RootCoordinator, animated: Bool) {
        viewControllersToChildCoordinators[coordinator.rootViewController] = coordinator

        pushViewController(coordinator.rootViewController, animated: animated)
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        childNavigationController.pushViewController(viewController, animated: animated)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        childNavigationController.dismiss(animated: flag, completion: completion)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        childNavigationController.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func popViewController(animated: Bool) {
        childNavigationController.popViewController(animated: animated)
    }

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        childNavigationController.setViewControllers(viewControllers, animated: animated)
    }

    func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        childNavigationController.setNavigationBarHidden(hidden, animated: animated)
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        var preferredStyle: UIStatusBarStyle
        if
            childNavigationController.topViewController is MasterBrowserViewController ||
                childNavigationController.topViewController is DarkPassphraseViewController ||
                childNavigationController.topViewController is DarkVerifyPassphraseViewController ||
                childNavigationController.topViewController is WalletCreatedController
        {
            preferredStyle = .default
        } else {
            preferredStyle = .lightContent
        }
        return preferredStyle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension NavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Necessary to get the child navigation controller’s interactive pop gesture recognizer to work.
        return true
    }
}

// MARK: - UINavigationControllerDelegate

extension NavigationController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController,
                              didShowViewController viewController: UIViewController, animated: Bool) {
        cleanUpChildCoordinators()
    }

    private func cleanUpChildCoordinators() {
        for viewController in viewControllersToChildCoordinators.keys {
            if !childNavigationController.viewControllers.contains(viewController) {
                viewControllersToChildCoordinators.removeValue(forKey: viewController)
            }
        }
    }
}
