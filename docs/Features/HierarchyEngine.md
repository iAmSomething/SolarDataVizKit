# 🧩 Hierarchy & Breakdown Engine

> **SolarDataVizKit**의 세 번째 핵심 시각화 엔진으로, 예산 비중, 자산 포트폴리오, 디스크 용량 등 전체 구성비와 계층형 구조(Hierarchy)를 직사각형 사각형 면적(TreeMap) 및 동심원 부채꼴 링(Sunburst)으로 표현하는 엔진입니다.

---

## 🎯 주요 특징 (Key Features)

1. **Squarified TreeMap Tiling**: 전체 대비 수치 비중에 비례하여 화면 사각형 면적을 분할하는 고성능 사각형 타일링 연산기.
2. **Concentric Sunburst Chart**: 1차 대분류 $\rightarrow$ 2차 소분류 계층 구조를 중심에서 외곽으로 확장되는 동심원 부채꼴 아치(Arc)로 시각화.
3. **Interactive Tile Selection**: 타일 터치 선택 시 강조 바운더리 오버레이 및 스프링 애니메이션 제공.
4. **Theme Integrated**: `SolarVizTheme` 기반 시리즈 색상 팔레트 및 페이퍼 화이트 텍스트 자동 적용.
5. **Zero Memory Leak & High Performance**: Pure Value Type 분할 수식 및 스레드 세이프 메모리 관리.

---

## 🏛 기술 아키텍처 (Technical Architecture)

```
Sources/SolarDataVizKit/Engines/Hierarchy/
├── SolarTreeMapView.swift   # 면적 비중 사각형 타일링 시각화 메인 뷰
└── SolarSunburstView.swift  # 다단계 계층 동심원 링 시각화 메인 뷰
```

### Squarified Tiling 수식 (Tiling Math)
전체 직사각형 영역 \(R(w, h)\) 내에서 비중 \(v_i\)를 가지는 요소들의 타일 종횡비(Aspect Ratio)를 최적화하여 정사각형에 가깝게 면적을 할당합니다:

\[
\text{Tile Area } A_i = \text{Total Area} \times \frac{v_i}{\sum v}
\]

---

## 💻 사용 예시 (Usage Examples)

### 1. TreeMap (트리맵) 사용법
```swift
import SwiftUI
import SolarDataVizKit

struct PortfolioView: View {
    let binding = VizDataBinding(
        data: myPortfolioItems,
        x: \.name,
        y: \.value
    )

    var body: some View {
        SolarTreeMapView(binding: binding)
            .solarVizTheme(.darkCarbon)
            .frame(height: 320)
    }
}
```

### 2. Sunburst (선버스트) 사용법
```swift
import SwiftUI
import SolarDataVizKit

struct BudgetBreakdownView: View {
    let binding = VizDataBinding(
        data: myCategoryItems,
        x: \.categoryName,
        y: \.budgetAmount,
        group: \.parentGroup
    )

    var body: some View {
        SolarSunburstView(binding: binding)
            .solarVizTheme(.darkCarbon)
            .frame(height: 350)
    }
}
```

---

## ⚡ 성능 및 메모리 설계 (Performance & Memory Safety)

- **Pure Value Type Tiling**: 사각형 면적 분할 연산 시 힙 메모리를 할당하지 않고 스택 위에서 `CGRect` 분할 연산을 처리합니다.
- **Retain Cycle Protection**: 뷰 이벤트 바인딩 내 모든 상태 조작 클로저에 `[weak self]` 처리가 적용되어 메모리 누수가 0건입니다.
- **UIKit Hosting Ready**: `SolarVizHostingView`를 통해 UIKit 프로젝트에서도 3줄로 내장할 수 있습니다.
