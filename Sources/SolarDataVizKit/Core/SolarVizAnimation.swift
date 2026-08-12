import SwiftUI

enum SolarVizAnimation {
    /// 데이터 최초 로딩 시 부드러운 Fade-in
    static let dataLoad: Animation = .easeOut(duration: 0.35)
    
    /// 면적 기반 레이아웃 재배치 (트리맵, 썬버스트)
    static let layoutReflow: Animation = .spring(response: 0.5, dampingFraction: 0.82)
    
    /// 클러스터 노드 합체/분리
    static let clusterMerge: Animation = .spring(response: 0.4, dampingFraction: 0.7)
    
    /// 툴팁 나타남/사라짐 (손가락 추적은 빨라야 함)
    static let tooltip: Animation = .easeInOut(duration: 0.15)
    
    /// 타일/호 선택 하이라이트
    static let selection: Animation = .spring(response: 0.3, dampingFraction: 0.7)
}
