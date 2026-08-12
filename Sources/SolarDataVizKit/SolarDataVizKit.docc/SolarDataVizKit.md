# ``SolarDataVizKit``

유려한 모션 애니메이션 기반 다차원 데이터 시각화 엔진 킷.

## Overview

`SolarDataVizKit`은 단순한 차트 렌더링 프레임워크가 아닙니다.
복잡한 수학 연산(K-Means 군집화, 교차점 검출, RBF 커널 비선형 추이)을 SwiftUI의 직관적인 선언형 문법과 결합하여, 최고 수준의 인터랙티브 데이터 시각화 경험을 제공합니다.

기존 데이터 모델을 수정할 필요 없이 100% Zero-Intrusion KeyPath 바인딩을 통해 데이터의 흐름을 엔진에 주입합니다.

## Topics

### Getting Started

- <doc:GettingStarted>

### Core Concepts

- ``VizDataBinding``
- ``SolarPlottable``
- ``SolarVizTheme``
- ``SolarVizHaptics``

### Visualization Engines

- ``SolarComparisonChartView``
- ``SolarDualComparisonChartView``
- ``SolarClusterScatterView``
- ``DensityHeatmapView``
- ``SolarTreeMapView``
- ``SolarSunburstView``
- ``SolarBayesianTrendView``
