//
//  CartDetailsView.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import SwiftUI

struct CartDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // ContentView와 상태를 공유하는 바인딩 변수들 (Values and user selections)
    @Binding var cartItems: [MenuItem]
    @Binding var serviceRate: Double // Slider 바인딩 (0.0 ~ 0.15)
    @Binding var taxRate: Double     // Stepper 바인딩 (0.0 ~ 0.20)
    @Binding var cardRate: Double    // Stepper 바인딩 (0.0 ~ 0.10)
    let budgetKRW: Int
    
    // 계산기 인스턴스 (DiningExpenseCalculator 활용)
    private var calculator: DiningExpenseCalculator {
        DiningExpenseCalculator(
            exchangeRate: 0.088,
            serviceRate: serviceRate,
            taxRate: taxRate,
            cardRate: cardRate
        )
    }
    
    private var result: (subtotal: Double, additionals: Double, grandTotal: Double, grandTotalKRW: Int) {
        calculator.calculateGrandTotal(items: cartItems)
    }
    
    private var subtotalKRW: Int {
        calculator.convertToKRW(localAmount: result.subtotal)
    }
    
    private var additionalsKRW: Int {
        calculator.convertToKRW(localAmount: result.additionals)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 장바구니 아이템 및 수량 조절 카드
                    cartItemsCard
                    
                    // 1. Additionals 설정 카드 (Selection and input components 집중 구간)
                    additionalsCard
                    
                    // 2. Total Price 요약 카드
                    totalPriceCard
                    
                    // 3. Budget 분석 카드
                    budgetAnalysisCard
                    
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Cart")
                        }
                        .foregroundColor(.black)
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    // 1. Additionals 카드 (Slider + Stepper)
    private var additionalsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Additionals")
                .font(.title3.bold())
            
            VStack(spacing: 16) {
                // (1) Service Charge: Slider 컴포넌트
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Service Charge:")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", serviceRate * 100))
                            .font(.subheadline.bold())
                    }
                    Slider(value: $serviceRate, in: 0.0...0.15, step: 0.001)
                        .tint(.gray)
                }
                
                Divider()
                
                // (2) Tax Charge: Stepper 컴포넌트
                HStack {
                    Text("Tax Charge:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(taxRate * 100))%")
                        .font(.subheadline.bold())
                        .frame(width: 45, alignment: .trailing)
                    
                    Stepper("", value: $taxRate, in: 0.0...0.20, step: 0.01)
                        .labelsHidden()
                }
                
                Divider()
                
                // (3) Card Charge: Stepper 컴포넌트
                HStack {
                    Text("Card Charge:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(cardRate * 100))%")
                        .font(.subheadline.bold())
                        .frame(width: 45, alignment: .trailing)
                    
                    Stepper("", value: $cardRate, in: 0.0...0.05, step: 0.01)
                        .labelsHidden()
                }
            }
            .padding(16)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(18)
        }
    }
    
    // 2. Total Price 카드
    private var totalPriceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Total Price")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                rowView(title: "Subtotal:", value: formatKRW(subtotalKRW))
                rowView(title: "Additionals:", value: formatKRW(additionalsKRW))
                Divider()
                rowView(title: "Grand Total:", value: formatKRW(result.grandTotalKRW), isBold: true)
            }
            .padding(16)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(18)
        }
    }
    
    // 3. Budget 카드
    private var budgetAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Budget")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                rowView(title: "Target Budget:", value: formatKRW(budgetKRW))
                rowView(title: "Grand Total:", value: formatKRW(result.grandTotalKRW))
                Divider()
                
                let diff = result.grandTotalKRW - budgetKRW
                if diff > 0 {
                    // 예산 초과 시: +표시와 함께 쉼표 포맷
                    rowView(title: "Over Budget:", value: "+\(formatKRW(diff))", isBold: true, valueColor: .red)
                } else {
                    // 예산 여유 시: 남은 금액 쉼표 포맷
                    rowView(title: "Remaining:", value: formatKRW(-diff), isBold: true, valueColor: .green)
                }
            }
            .padding(16)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(18)
        }
    }
    
    private func rowView(title: String, value: String, isBold: Bool = false, valueColor: Color = .primary) -> some View {
        HStack {
            Text(title)
                .font(isBold ? .body.bold() : .body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(isBold ? .headline.bold() : .subheadline)
                .foregroundColor(valueColor)
        }
    }
    
    private func formatKRW(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "원"
    }
    
    // MARK: - 장바구니 아이템 편집 카드
    private var cartItemsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Items in Cart")
                    .font(.title3.bold())
                Spacer()
                Text("\(cartItems.reduce(0) { $0 + $1.count })개")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                if cartItems.isEmpty {
                    Text("장바구니가 비어 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(cartItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(item.rawName)
                                        .font(.subheadline.bold())
                                    
                                    // Core ML 카테고리 뱃지
                                    Text(item.category)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                                if item.translatedName != item.rawName {
                                    Text("(\(item.translatedName))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // [-] 수량 [+] 버튼
                            HStack(spacing: 10) {
                                Button(action: { decrementItem(item) }) {
                                    Image(systemName: item.count == 1 ? "trash" : "minus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(item.count == 1 ? .red : .primary)
                                        .frame(width: 28, height: 28)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                                
                                Text("\(item.count)")
                                    .font(.subheadline.bold())
                                    .frame(minWidth: 20)
                                
                                Button(action: { incrementItem(item) }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        if item.id != cartItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray5).opacity(0.6))
            .cornerRadius(18)
        }
    }
    
    private func incrementItem(_ item: MenuItem) {
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            cartItems[index].count += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func decrementItem(_ item: MenuItem) {
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            if cartItems[index].count > 1 {
                cartItems[index].count -= 1
            } else {
                cartItems.remove(at: index)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
