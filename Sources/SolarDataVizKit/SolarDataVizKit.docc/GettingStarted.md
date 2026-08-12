# 실무 연동 가이드 (Getting Started)

10분 만에 끝내는 `SolarDataVizKit` 시각화 연동 가이드.

## 1. 개요

`SolarDataVizKit`은 도메인 모델을 침범하지 않습니다. 여러분이 기존에 사용하던 구조체나 클래스 그대로 프레임워크에 주입할 수 있습니다. 이를 위해 `VizDataBinding`과 `SolarPlottable`이라는 강력한 개념을 사용합니다.

## 2. SolarPlottable 프로토콜의 이해

차트는 내부적으로 X축과 Y축 좌표를 계산하기 위해 `Double` 값을 필요로 합니다.
하지만 실제 앱 데이터는 `Date`(시간), `String`(카테고리), `Int` 등 다양한 타입으로 이루어져 있습니다.

`SolarPlottable` 프로토콜은 이러한 원시 타입들을 $O(1)$의 비용으로 자동 변환(Scaling)해 줍니다.
- **`Double`, `CGFloat`, `Int`**: 값 그대로 매핑.
- **`Date`**: `timeIntervalSince1970`을 기준으로 정밀하게 변환.
- **`String`**: 내부 해시 및 카테고리 인덱싱 기법을 통해 X축 또는 Y축 위치로 자동 할당.

## 3. VizDataBinding 생성하기

차트 렌더링의 핵심 객체는 ``VizDataBinding``입니다. 데이터를 변경할 필요 없이 `KeyPath`만 넘기면 됩니다.

```swift
import SolarDataVizKit

struct DailyStep: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

let myData = [
    DailyStep(date: .now, steps: 8400),
    DailyStep(date: .now.addingTimeInterval(86400), steps: 10200)
]

// VizDataBinding 생성
let binding = VizDataBinding(
    data: myData,
    x: \.date,    // X축에는 Date가 자동으로 스케일링 됨
    y: \.steps    // Y축에는 Int가 자동으로 스케일링 됨
)
```

## 4. 뷰 렌더링 및 모디파이어 적용

생성한 바인딩을 차트 뷰에 넘기면 렌더링이 완료됩니다. 테마나 햅틱 등은 SwiftUI 환경(Environment) 모디파이어로 손쉽게 제어할 수 있습니다.

```swift
SolarComparisonChartView(binding: binding, seriesA: "걸음 수")
    .solarVizTheme(.darkCarbon)       // 다크 카본 테마 적용
    .solarVizHapticsEnabled(true)     // 햅틱 진동 켜기
    .frame(height: 300)
```

## 5. 인터랙션 콜백 처리

유저가 차트의 특정 데이터를 탭하거나 스크러빙(Scrubbing)했을 때 콜백을 통해 원래 데이터를 돌려받을 수 있습니다.

```swift
SolarTreeMapView(binding: binding)
    .onTileSelected { item in
        // item은 우리가 주입했던 DailyStep 객체입니다!
        print("선택된 걸음 수: \(item.steps)")
    }
```
