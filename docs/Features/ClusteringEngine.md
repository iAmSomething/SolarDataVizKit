# 🫧 Clustering & Density Engine

> **SolarDataVizKit**의 두 번째 핵심 시각화 엔진으로, 2차원 공간 상의 데이터 포인트를 산점도(Scatter Plot) 및 가변 버블(Bubble Chart)로 시각화하고 거리 임계값에 반응해 노드가 유체 스프링 모핑으로 합쳐지는 엔진입니다.

---

## 🎯 주요 특징 (Key Features)

1. **Interactive 2D Scatter & Bubble Chart**: X, Y 좌표 위치와 수치 가중치(Radius Weight)에 따른 2차원 원 배치.
2. **K-Means 거리 기반 유체 클러스터링 (Auto-Merging Cluster Nodes)**: 데이터 노드 간 거리가 거리 임계값 \(R\) 이내로 근접하면 물리 스프링 애니메이션으로 하나의 원으로 뭉쳐지며 `+N` 개수 뱃지 생성.
3. **CoreHaptics Cluster Snap Feedback**: 노드가 합쳐지거나 분리되는 순간 탄성 `playClusterSnap()` 햅틱 피드백 트리거.
4. **Density Heatmap Overlay**: 데이터 밀집 구역을 가우시안 블러 및 틴트 그래디언트 핫스팟으로 강조.
5. **Zero Memory Leak & High Performance**: Pure Value Type 거리 계산기 및 스레드 세이프 메모리 관리.

---

## 🏛 기술 아키텍처 (Technical Architecture)

```
Sources/SolarDataVizKit/Engines/Clustering/
├── ClusterNodeCalculator.swift     # K-Means 거리 기반 군집화 계산기 (Pure Value Type)
├── SolarClusterScatterView.swift    # 2D 산점도 및 스프링 모핑 클러스터 메인 뷰
└── DensityHeatmapView.swift         # 밀도 히트맵 핫스팟 오버레이 뷰
```

### 거리 계산 수식 (Euclidean Distance Formula)
두 데이터 포인트 \(P_1(x_1, y_1)\)과 \(P_2(x_2, y_2)\) 사이의 유클리드 거리가 산출 기준 거리 임계값 \(R\)보다 낮을 경우 합체 클러스터 노드로 통합됩니다:

\[
d(P_1, P_2) = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2} \le R
\]

---

## 💻 사용 예시 (Usage Examples)

### 1. SwiftUI 사용법
```swift
import SwiftUI
import SolarDataVizKit

struct ScatterClusterDemoView: View {
    let binding = VizDataBinding(
        data: myScatterPoints,
        x: \.xPos,
        y: \.yPos
    )

    var body: some View {
        SolarClusterScatterView(
            binding: binding,
            clusterRadiusThreshold: 45.0
        )
        .solarVizTheme(.darkCarbon)
        .frame(height: 350)
    }
}
```

### 2. UIKit 사용법
```swift
import UIKit
import SolarDataVizKit

final class ClusterViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let scatterView = SolarClusterScatterView(
            binding: myBinding,
            clusterRadiusThreshold: 50.0
        )
        let hostingView = SolarVizHostingView(rootView: scatterView)
        hostingView.frame = CGRect(x: 16, y: 100, width: view.bounds.width - 32, height: 350)
        view.addSubview(hostingView)
    }
}
```

---

## ⚡ 성능 및 메모리 설계 (Performance & Memory Safety)

- **Stateless Value Type Engine**: `ClusterNodeCalculator`는 힙 메모리 할당 없이 스택 위에서 `CGPoint` 유클리드 거리를 산출합니다.
- **60fps Spring Motion**: SwiftUI `.spring(response: 0.4, dampingFraction: 0.75)` 애니메이션을 통해 부드러운 노드 모핑을 연출합니다.
- **Retain Cycle Safety**: 클로저 및 스크러빙 제스처 내 `[weak self]` 처리를 적용하여 메모리 누수를 완전히 차단합니다.
