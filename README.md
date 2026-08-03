# 🌞 SolarDataVizKit

> **SolarDataVizKit**은 단순한 1차원 차트 그리기를 넘어, 앱 사용자가 자신의 데이터/통계를 보며 몰입하고 즐길 수 있는 **"유려한 모션 애니메이션 기반 다차원 데이터 시각화 엔진 킷"**입니다.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-iOS%2016.0%2B%20%7C%20macOS%2013.0%2B-blue.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 핵심 특징 (Key Highlights)

1. **Zero-Intrusion KeyPath 바인딩 (`VizDataBinding`)**:
   기존 도메인 모델(`struct MyModel: SolarVizDataPoint`)을 수정할 필요 없이 KeyPath(`\.date`, `\.amount`)만 지정하면 시각화 엔진에 바인딩됩니다.
2. **3대 핵심 시각화 엔진**:
   - 📊 **Grouped Comparison Engine**: 다중 라인/막대 비교, 자동 교차 영역 그라데이션 필, 스크러빙 실시간 델타 툴팁(`▲ +15.4%`).
   - 🫧 **Clustering & Density Engine**: 2D 산점도 & 가변 버블 차트, K-Means 유체 스프링 모핑(`+N` 뱃지), 가우시안 블러 히트맵.
   - 🧩 **Hierarchy Engine**: Squarified 사각형 타일링(TreeMap) 및 계층형 동심원 링 차트(Sunburst).
3. **생동감 있는 CoreHaptics 통합**:
   - 교차점 도달 시 묵직한 `playImpact(.medium)` 피드백.
   - 노드 합체/분리 시 탄성 `playClusterSnap()` 햅틱 연동.
4. **Dark Warm-Tech 디자인 시스템 (`SolarVizTheme`)**:
   - 웜 카본 블랙(#0b0a09), 페이퍼 화이트(#f5f4f2), 웜 오렌지(#ff6b00) 액센트 기반 프리미엄 UI 및 커스텀 테마 지원.
5. **Swift 6 Strict Concurrency & Zero Memory Leak**:
   - `@MainActor` 기반 UI 스레드 안전성 보장 및 힙 할당 최소화 Pure Value Type 연산 엔진.
6. **SwiftUI & UIKit 100% 대칭 지원 (`SolarVizHostingView`)**.

---

## 📁 기능별 상세 문서 (Feature Documentation)

- 📊 [Grouped Comparison Engine 문서](docs/Features/GroupedComparisonEngine.md)
- 🫧 [Clustering & Density Engine 문서](docs/Features/ClusteringEngine.md)
- 🧩 [Hierarchy Engine 문서](docs/Features/HierarchyEngine.md)

---

## 💻 빠른 시작 (Quick Start)

### 1. Swift Package Manager 설치
```swift
dependencies: [
    .package(url: "https://github.com/SolarKits/SolarDataVizKit.git", from: "1.0.0")
]
```

### 2. SwiftUI 예시
```swift
import SwiftUI
import SolarDataVizKit

struct SalesComparisonView: View {
    let binding = VizDataBinding(
        data: mySalesData,
        x: \.month,
        y: \.revenue,
        group: \.year
    )

    var body: some View {
        SolarComparisonChartView(
            binding: binding,
            seriesA: "2026 Sales",
            seriesB: "2025 Sales"
        )
        .solarVizTheme(.darkCarbon)
        .frame(height: 300)
    }
}
```

### 3. UIKit 예시
```swift
import UIKit
import SolarDataVizKit

final class DashboardViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let chartView = SolarComparisonChartView(binding: myBinding)
        let hostingView = SolarVizHostingView(rootView: chartView)
        hostingView.frame = CGRect(x: 16, y: 100, width: view.bounds.width - 32, height: 300)
        view.addSubview(hostingView)
    }
}
```

---

## 🧪 테스트 실행 (Running Tests)

```bash
swift test --package-path SolarDataVizKit
```

---

## 📄 License
MIT License. Copyright (c) 2026 SolarKits.
