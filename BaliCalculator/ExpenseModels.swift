//
//  ExpenseModels.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import Foundation
import CoreML

// 메뉴 아이템 데이터 구조체
struct MenuItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let rawName: String
    let translatedName: String
    let category: String
    let localPrice: Double
    var count: Int = 0
}

// 부모 클래스: 기본 환율 및 기본 환산 연산
class BaseExpenseCalculator {
    var exchangeRate: Double
    
    init(exchangeRate: Double = 0.080) {
        self.exchangeRate = exchangeRate
    }
    
    // 현지 통화를 원화 환산 (10원 단위 반올림)
    func convertToKRW(localAmount: Double) -> Int {
        let rawKRW = localAmount * exchangeRate
        return Int((rawKRW / 10.0).rounded() * 10)
    }
    
    // 장바구니 아이템 순수 현지 금액 합계 (sum)
    func calculateSubtotal(items: [MenuItem]) -> Double {
        return items.reduce(0) { total, item in
            total + (item.localPrice * Double(item.count))}
    }
}

// 자식 클래스: 복리 세금 및 수수료 계산기 (inheritance 적용)
class DiningExpenseCalculator: BaseExpenseCalculator {
    //식당 특화 추가 프로퍼티
    var serviceRate: Double
    var taxRate: Double
    var cardRate: Double
    
    init(
        exchangeRate: Double = 0.088,
        serviceRate: Double = 0.058,
        taxRate: Double = 0.10,
        cardRate: Double = 0.02
    ) {
        self.serviceRate = serviceRate
        self.taxRate = taxRate
        self.cardRate = cardRate
        super.init(exchangeRate: exchangeRate)
    }
    
    //최종 결제 금액 묶어서 변환
    func calculateGrandTotal(items: [MenuItem]) -> (subtotal: Double, additionals: Double, grandTotal: Double, grandTotalKRW: Int) {
        let subtotal = calculateSubtotal(items: items)
        
        //복리 과세 계산
        let withService = subtotal * (1.0 + serviceRate)
        let withTax = withService * (1.0 + taxRate)
        let finalGrandTotal = withTax * (1.0 + cardRate)
        
        let additionals = finalGrandTotal - subtotal
        
        let grandTotalKRW = convertToKRW(localAmount: finalGrandTotal)
        
        return (subtotal, additionals, finalGrandTotal, grandTotalKRW)
        
    }
}

// coreML 모델 추론 wrapper 클래스
final class MenuClassifierService {
    private var model: MenuCategoryClassifier?

    init() {
        do {
            let config = MLModelConfiguration()
            self.model = try MenuCategoryClassifier(configuration: config)
        } catch {
            print("Failed to load Core ML model: \(error)")
        }
    }

    func predictCategory(for menuName: String) -> String {
        let lower = menuName.lowercased()

        // [1차 방어선] 명확한 키워드 우선 규칙 매핑
        // 1. 식사류
        if lower.contains("nasi") || lower.contains("mie") || lower.contains("kwetiaw") || lower.contains("bihun") || lower.contains("bakso") {
            return "식사류"
        }
        // 2. 음료
        if lower.contains("es ") || lower.contains("jus") || lower.contains("kopi") || lower.contains("teh") || lower.contains("beer") || lower.contains("air ") {
            return "음료"
        }
        // 3. 육류 (Sop Buntut, Sop Iga 방어)
        if lower.contains("buntut") || lower.contains("iga") || lower.contains("sapi") || lower.contains("ayam") || lower.contains("babi") || lower.contains("kambing") || lower.contains("bebek") || lower.contains("rendang") {
            return "육류"
        }
        // 4. 해산물
        if lower.contains("ikan") || lower.contains("udang") || lower.contains("cumi") || lower.contains("kepiting") || lower.contains("kerang") || lower.contains("gurame") || lower.contains("kakap") {
            return "해산물"
        }
        // 5. 채소류
        if lower.contains("kangkung") || lower.contains("toge") || lower.contains("kuciwis") || lower.contains("sayur") || lower.contains("gado gado") || lower.contains("capcay") {
            return "채소류"
        }

        // [2차 머신러닝 추론] 규칙에 걸리지 않는 미지의 메뉴는 Core ML에게 위임
        guard let model = model,
              let output = try? model.prediction(text: menuName) else {
            return "기타"
        }
        return output.label
    }
}
