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
class MenuClassifierService {
    private var model: MenuCategoryClassifier?
    
    init() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            self.model = try MenuCategoryClassifier(configuration: config)
        } catch {
            print("Core ML 모델 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // 메뉴 이름 받아 카테고리 라벨을 반환하는 매서드
    func predictCategory(for menuName: String) -> String {
        guard let model = model else { return "기타" }
        
        do {
            let output = try model.prediction(text: menuName)
            return output.label
        } catch {
            print("카테고리 추론 실패 (\(menuName)): \(error.localizedDescription)")
            return "기타"
        }
        
    }
    
}
