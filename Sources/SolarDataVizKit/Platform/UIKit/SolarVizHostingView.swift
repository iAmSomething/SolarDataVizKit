#if canImport(UIKit)
import UIKit
import SwiftUI

/// UIKit ViewController 및 View에 SwiftUI 기반 SolarDataVizKit 엔진을 내장할 수 있도록 지원하는 무누수 컨테이너 뷰입니다.
///
/// ## Overview
/// `SolarVizHostingView`는 Auto Layout 제약 조건을 상위 뷰에 맞추고,
/// `removeFromSuperview` 호출 시 내부 `UIHostingController` 계층을 깨끗하게 정리하여 메모리 누수를 방지합니다.
///
/// ## Example
/// ```swift
/// let chartView = SolarComparisonChartView(binding: myBinding)
/// let hostingView = SolarVizHostingView(rootView: chartView)
/// myUIKitView.addSubview(hostingView)
/// ```
@MainActor
public final class SolarVizHostingView<Content: View>: UIView {
    private var hostingController: UIHostingController<Content>?

    /// 루트 SwiftUI 뷰를 감싸는 호스팅 뷰를 생성합니다.
    ///
    /// - Parameter rootView: 내장할 SwiftUI 뷰 인스턴스
    public init(rootView: Content) {
        let controller = UIHostingController(rootView: rootView)
        self.hostingController = controller
        super.init(frame: .zero)

        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controller.view)

        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: topAnchor),
            controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            controller.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 뷰가 윈도우 계층에 추가될 때 부모 UIViewController를 탐색하여 addChild 및 didMove(toParent:) 생명주기를 연결합니다.
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, let controller = hostingController {
            if let parentVC = findParentViewController() {
                if controller.parent != parentVC {
                    parentVC.addChild(controller)
                    controller.didMove(toParent: parentVC)
                }
            }
        }
    }

    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let vc = responder as? UIViewController {
                return vc
            }
        }
        return nil
    }

    /// 뷰가 슈퍼뷰에서 제거될 때 UIHostingController의 뷰 계층 및 참조를 해제하여 메모리 누수를 차단합니다.
    override public func removeFromSuperview() {
        hostingController?.view.removeFromSuperview()
        hostingController?.willMove(toParent: nil)
        hostingController?.removeFromParent()
        hostingController = nil
        super.removeFromSuperview()
    }
}
#endif
