# 📊 Grouped Comparison Engine

> **SolarDataVizKit**의 첫 번째 핵심 시각화 엔진으로, 두 개 이상의 데이터 시리즈(예: `지난달 vs 이번달`, `A 제품 vs B 제품`)를 겹쳐서 다차원 비교 분석을 수행하는 엔진입니다.

---

## 🎯 주요 특징 (Key Features)

1. **Swift Charts 연동**: iOS 16+ `Charts` 프레임워크 기반의 하드웨어 가속 렌더링.
2. **교차 영역 자동 강조 (Intersection Highlight)**: 두 시리즈 데이터 선이 서서히 역전되는 교차점(Intersection Point)을 수식 계산하여 사이 영역을 반투명 그라데이션 필 패스로 강조.
3. **실시간 스크러빙 & 델타 글래스 툴팁**: 손가락 드래그 스크러빙 시 위치별 두 시리즈 간의 증감 차이(`지난달 대비 +15.4% (▲ 120,000원)`)를 실시간 계산하여 글래스모피즘 툴팁으로 표시.
4. **CoreHaptics 통합**: 터치 이동 중 데이터선 교차점에 도달하는 순간 묵직한 `playImpact(.medium)` 햅틱 피드백 발사.
5. **Zero Memory Leak & High Performance**: Pure Value Type 수학 계산 파이프라인 및 스레드 세이프 메모리 관리.

---

## 🏛 기술 아키텍처 (Technical Architecture)

```
Sources/SolarDataVizKit/Engines/Comparison/
├── SolarComparisonChartView.swift     # SwiftUI 차트 뷰 메인 컴포넌트
├── IntersectionPathCalculator.swift   # 교차점 & 영점 폴리곤 파스 계산 엔진 (Pure Value Type)
└── DeltaTooltipOverlay.swift          # 글래스모피즘 차이값 툴팁 오버레이
```

### 교차점 산출 공식 (Intersection Math)
두 선분 \(AB\)와 \(CD\)의 2차원 교차점 \(P(x, y)\)는 다음 행렬식(Determinant) 공식을 통해 힙 할당 없이 \(O(N)\) 시간에 선형 계산됩니다:

\[
t = \frac{(x_1 - x_3)(y_3 - y_4) - (y_1 - y_3)(x_3 - x_4)}{(x_1 - x_2)(y_3 - y_4) - (y_1 - y_2)(x_3 - x_4)}
\]

---

## 💻 사용 예시 (Usage Examples)

### 1. SwiftUI 사용법
```swift
import SwiftUI
import SolarDataVizKit

struct ExpenseComparisonView: View {
    let salesBinding = VizDataBinding(
        data: myExpenses,
        x: \.month,
        y: \.amount,
        group: \.category
    )

    var body: some View {
        SolarComparisonChartView(
            binding: salesBinding,
            seriesA: "Last Month",
            seriesB: "This Month"
        )
        .solarVizTheme(.darkCarbon)
        .frame(height: 300)
    }
}
```

### 2. UIKit 사용법
```swift
import UIKit
import SolarDataVizKit

final class DashboardViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let chartView = SolarComparisonChartView(
            binding: myBinding,
            seriesA: "2025",
            seriesB: "2026"
        )
        let hostingView = SolarVizHostingView(rootView: chartView)
        hostingView.frame = CGRect(x: 16, y: 100, width: view.bounds.width - 32, height: 300)
        view.addSubview(hostingView)
    }
}
```

---

## ⚡ 성능 및 메모리 설계 (Performance & Memory Safety)

- **Pure Value Types**: `IntersectionPathCalculator`는 힙 메모리를 할당하지 않고 스택 위에서 `CGPoint` 연산을 처리합니다.
- **Retain Cycle Protection**: 툴팁 및 제스처 바인딩 내 모든 상태 조작 클로저에 `[weak self]` 처리가 적용되어 뷰 파괴 시 메모리 누수가 발생하지 않습니다.
- **Frame Rate Guarantee**: 60fps / 120fps ProMotion 스크롤 및 스크러빙 터치 이벤트를 완벽하게 지원합니다.
