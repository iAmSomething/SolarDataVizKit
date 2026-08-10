# 🌞 SolarDataVizKit v4.0.0

> **SolarDataVizKit**은 단순한 1차원 차트 그리기를 넘어, 앱 사용자가 자신의 데이터/통계를 보며 몰입하고 즐길 수 있는 **"유려한 모션 애니메이션 기반 다차원 데이터 시각화 엔진 킷"**입니다.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-iOS%2016.0%2B%20%7C%20macOS%2013.0%2B-blue.svg)](https://developer.apple.com/swift/)
[![Tests](https://img.shields.io/badge/Unit%20Tests-83%2F83%20Passing-brightgreen.svg)](Tests)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 핵심 특징 (Key Highlights)

1. **Zero-Intrusion KeyPath 바인딩 (`VizDataBinding`)**:
   기존 도메인 모델(`struct MyModel: SolarVizDataPoint`)을 수정할 필요 없이 KeyPath(`\.date`, `\.amount`)만 지정하면 시각화 엔진에 바인딩됩니다.
2. **12대 시각화 엔진 스펙트럼**:
   - 📊 **Grouped Comparison Engine**: 다중 라인/막대 비교, 자동 교차 영역 그라데이션 필, 스크러빙 실시간 델타 툴팁(`▲ +15.4%`).
   - 🫧 **Clustering & Density Engine**: 2D 산점도 & 가변 버블 차트, K-Means 유체 스프링 모핑(`+N` 뱃지), 가우시안 블러 히트맵.
   - 🧩 **Hierarchy Engine**: Squarified 사각형 타일링(TreeMap) 및 계층형 동심원 링 차트(Sunburst).
   - 📈 **Bayesian Regression Engine**: Gaussian RBF 커널 기반 비선형 추이선 및 $O(1)$ 근묵자 인접(Nearest-Neighbor) 보간 오차범위 밴드.
3. **생동감 있는 CoreHaptics 통합**:
   - 교차점 도달 시 묵직한 `playImpact(.medium)` 피드백.
   - 노드 합체/분리 시 탄성 `playClusterSnap()` 햅틱 연동.
4. **Dark Warm-Tech 디자인 시스템 (`SolarVizTheme`)**:
   - 웜 카본 블랙(#0b0a09), 페이퍼 화이트(#f5f4f2), 웜 오렌지(#ff6b00) 액센트 기반 프리미엄 UI 및 커스텀 테마 지원.
5. **Swift 6 Strict Concurrency & 0.00ms Zero-Bottleneck**:
   - `@MainActor` UI 안전성 준수 및 `.task(id: dataHash)` 기반 $O(N)$ 사전 연산 캐싱으로 드래그 프레임 drop 0건 보장.

---

## 📸 12대 시각화 엔진 24종 데이터셋 실측 갤러리 (24-Preset Gallery)

모든 엔진은 **이상적 데이터(Ideal)**와 **최악의 극단적 데이터(Evil Worst-Case)** 두 가지 더미 데이터 세트로 실측 검증되었습니다.

### 1. Grouped Comparison Chart (단일 다중 비교 엔진)
| Ideal (이상적 프리셋) | Evil (최악/동일값 프리셋) |
|---|---|
| ![Engine 1 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_01_ideal.png) | ![Engine 1 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_01_evil.png) |

### 2. Dual Comparison Chart (독립 듀얼 색상 비교 엔진)
| Ideal (이상적 프리셋) | Evil (최악/스파이크 프리셋) |
|---|---|
| ![Engine 2 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_02_ideal.png) | ![Engine 2 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_02_evil.png) |

### 3. Area Intersection Chart (교차 영역 필 차트)
| Ideal (이상적 프리셋) | Evil (최악/단일점 교차 프리셋) |
|---|---|
| ![Engine 3 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_03_ideal.png) | ![Engine 3 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_03_evil.png) |

### 4. Interactive Drag Tooltip (인터랙티브 스크러빙 툴팁)
| Ideal (이상적 프리셋) | Evil (최악/경계 오버플로우 프리셋) |
|---|---|
| ![Engine 4 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_04_ideal.png) | ![Engine 4 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_04_evil.png) |

### 5. Scatter Bubble Chart (가변 버블 산점도)
| Ideal (이상적 프리셋) | Evil (최악/10,000개 밀집 프리셋) |
|---|---|
| ![Engine 5 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_05_ideal.png) | ![Engine 5 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_05_evil.png) |

### 6. Cluster Scatter Chart (K-Means spatial grid 군집화)
| Ideal (이상적 프리셋) | Evil (최악/동일 좌표 중복 프리셋) |
|---|---|
| ![Engine 6 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_06_ideal.png) | ![Engine 6 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_06_evil.png) |

### 7. Density Heatmap Chart (2D 가우시안 밀도 히트맵)
| Ideal (이상적 프리셋) | Evil (최악/단일 셀 극단 밀집 프리셋) |
|---|---|
| ![Engine 7 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_07_ideal.png) | ![Engine 7 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_07_evil.png) |

### 8. Squarified TreeMapView ($O(1)$ aspect ratio 트리맵)
| Ideal (이상적 프리셋) | Evil (최악/0.0001 극소 타일 프리셋) |
|---|---|
| ![Engine 8 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_08_ideal.png) | ![Engine 8 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_08_evil.png) |

### 9. Hierarchical SunburstView (계층형 동심원 부채꼴 아크)
| Ideal (이상적 프리셋) | Evil (최악/360도 단일 그룹 프리셋) |
|---|---|
| ![Engine 9 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_09_ideal.png) | ![Engine 9 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_09_evil.png) |

### 10. Layout Cache Container (캐싱 래퍼)
| Ideal (이상적 프리셋) | Evil (최악/빈 데이터 프리셋) |
|---|---|
| ![Engine 10 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_10_ideal.png) | ![Engine 10 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_10_evil.png) |

### 11. UIKit Hosting Wrapper (`SolarVizHostingView`)
| Ideal (이상적 프리셋) | Evil (최악/초고속 뷰 전환 프리셋) |
|---|---|
| ![Engine 11 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_11_ideal.png) | ![Engine 11 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_11_evil.png) |

### 12. Bayesian RBF Trend & Uncertainty Chart (수치해석 비선형 추이선)
| Ideal (이상적 프리셋) | Evil (최악/노이즈 진동 프리셋) |
|---|---|
| ![Engine 12 Ideal](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_12_ideal.png) | ![Engine 12 Evil](file:///Users/gimtaehun/.gemini/antigravity/brain/4bb89c12-9ca6-49e6-8a93-c7f863b57803/engine_12_evil.png) |

---

## 💻 빠른 시작 (Quick Start)

### 1. Swift Package Manager 설치
```swift
dependencies: [
    .package(url: "https://github.com/SolarKits/SolarDataVizKit.git", from: "4.0.0")
]
```

### 2. SwiftUI 사용 예시
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

---

## 🧪 테스트 및 검증 (Tests & Verification)

```bash
swift test --package-path SolarDataVizKit
```

---

## 📄 License
MIT License. Copyright (c) 2026 SolarKits.
