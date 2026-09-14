//
//  BaliCalculatorApp.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import SwiftUI

@main
struct BaliCalculatorApp: App {
    
    // 앱이 실행될 때 가장 먼저 한 번 호출되는 초기화 블록
    init() {
        testDiningCalculator()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // 1-3단계 테스트 함수
    func testDiningCalculator() {
        // 1. Core ML 분류기 인스턴스화
        let classifier = MenuClassifierService()

        // 2. 테스트할 메뉴 이름 목록
        let sampleNames = ["Tumis Kangkung", "Ikan Bakar", "Ayam Goreng", "Es Teh Manis"]

        print("--- [Core ML 추론 검증 결과] ---")
        for name in sampleNames {
            let label = classifier.predictCategory(for: name)
            print("메뉴: \(name) -> 카테고리: [\(label)]")
        }

        // 3. 기존 상속 계산기 테스트 유지
        let items = [
            MenuItem(rawName: "Tumis Kangkung", translatedName: "모닝글로리 볶음", category: classifier.predictCategory(for: "Tumis Kangkung"), localPrice: 15000, count: 1),
            MenuItem(rawName: "Tumis Kuciwis", translatedName: "미니 양배추 볶음", category: classifier.predictCategory(for: "Tumis Kuciwis"), localPrice: 15000, count: 2),
            MenuItem(rawName: "Tumis Toge", translatedName: "숙주 볶음", category: classifier.predictCategory(for: "Tumis Toge"), localPrice: 15000, count: 1)
        ]

        let calculator = DiningExpenseCalculator()
        let result = calculator.calculateGrandTotal(items: items)
        print("원화 최종 결제액: 약 \(result.grandTotalKRW)원")
    }
}
