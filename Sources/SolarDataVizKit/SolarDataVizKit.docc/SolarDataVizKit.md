# ``SolarDataVizKit``

유려한 모션 애니메이션 기반 다차원 데이터 시각화 엔진 프레임워크입니다.

## Overview

**SolarDataVizKit**은 단순한 1차원 차트 그리기를 넘어, 앱 사용자가 자신의 데이터/통계를 보며 몰입하고 즐길 수 있도록 돕는 프리미엄 iOS/macOS 시각화 SDK입니다.

- **Zero-Intrusion KeyPath 바인딩**: 도메인 모델 변경 없이 KeyPath(`\.date`, `\.amount`)만으로 바인딩.
- **Swift 6 Strict Concurrency Safe**: `@MainActor` 격리 및 데이터 레이스 차단.
- **Dark Warm-Tech 디자인 시스템**: 웜 카본 블랙(#0b0a09) 및 프리미엄 글래스모피즘 테마.
- **CoreHaptics 통합**: 데이터 교차점 및 클러스터 노드 스냅 시 촉각 피드백 발사.
- **Zero-Overhead Layout Caching**: `SolarVizLayoutCache`를 통해 SwiftUI `body` 재평가 시 0ms 연산 보장.

## Topics

### Essentials
- ``SolarVizDataPoint``
- ``SolarGroupedVizDataPoint``
- ``SolarDefaultDataPoint``
- ``VizDataBinding``

### Core Systems
- ``SolarVizTheme``
- ``SolarVizHaptics``
- ``SolarVizLayoutCache``

### Comparison Engine
- ``SolarComparisonChartView``
- ``IntersectionPathCalculator``
- ``DeltaTooltipOverlay``

### Clustering Engine
- ``SolarClusterScatterView``
- ``ClusterNodeCalculator``
- ``ClusterNode``
- ``DensityHeatmapView``

### Hierarchy Engine
- ``SolarTreeMapView``
- ``TreeTile``
- ``SolarSunburstView``
- ``SunburstArc``

### UIKit Integration
- ``SolarVizHostingView``
