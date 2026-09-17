//
//  ContentView.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import SwiftUI

struct ContentView: View {
    // 1. 상태 변수 (Values & User Selections)
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var scannedItems: [MenuItem] = []
    
    // 예산 및 장바구니 상태
    @State private var budgetKRW: Int = 5500
    @State private var budgetInput: String = "5500"
    @FocusState private var isBudgetFocused: Bool
    @State private var cartItems: [MenuItem] = []
    @State private var showCartDetails = false
    
    // 세금/수수료 설정 (기본값)
    @State private var serviceRate: Double = 0.058 // 5.8%
    @State private var taxRate: Double = 0.10      // 10%
    @State private var cardRate: Double = 0.02     // 2%
    
    // [추가] 기본 생성자 (앱 실제 실행용)
    init() {}
    
    // [추가] 프리뷰 및 테스트용 생성자
    init(mockItems: [MenuItem]) {
        _scannedItems = State(initialValue: mockItems)
    }
    
    
    // 서비스 인스턴스
    private let ocrService = VisionOCRService()
    private let parserService = MenuParserService()
    
    // 계산기 (상속 적용된 DiningExpenseCalculator)
    private var calculator: DiningExpenseCalculator {
        DiningExpenseCalculator(
            exchangeRate: 0.088,
            serviceRate: serviceRate,
            taxRate: taxRate,
            cardRate: cardRate
        )
    }
    
    // 장바구니 연산 프로퍼티
    private var totalItemCount: Int {
        cartItems.reduce(0) { $0 + $1.count }
    }
    
    private var calculationResult: (subtotal: Double, additionals: Double, grandTotal: Double, grandTotalKRW: Int) {
        calculator.calculateGrandTotal(items: cartItems)
    }
    
    private var isOverBudget: Bool {
        calculationResult.grandTotalKRW > budgetKRW && !cartItems.isEmpty
    }
    
    private var overBudgetAmount: Int {
        max(0, calculationResult.grandTotalKRW - budgetKRW)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()
            // 2. [추가] 리퀴드 글래스 앰비언트 라이트 레이어
            GeometryReader { proxy in
                ZStack {
                    // 상단 좌측 은은한 블루/민트 글로우 (Budget Bar 투과용)
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 65)
                        .offset(x: -60, y: -40)
                    
                    // 중간 우측 은은한 오렌지/앰버 글로우 (메뉴 리스트 투과용)
                    Circle()
                        .fill(Color.orange.opacity(0.10))
                        .frame(width: 240, height: 240)
                        .blur(radius: 60)
                        .offset(x: proxy.size.width - 180, y: proxy.size.height * 0.35)
                    
                    // 하단 중앙 은은한 인디고 글로우 (하단 Liquid Glass Cart Bar 투과용)
                    Circle()
                        .fill(Color.indigo.opacity(0.10))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .offset(x: proxy.size.width * 0.2, y: proxy.size.height - 180)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false) // 중요: 배경 터치 간섭 차단
            
            // 메인 콘텐츠 레이어
            VStack(spacing: 0) {
                // 상단 Budget Bar
                topBudgetBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .zIndex(1)
                    
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 메뉴판 프리뷰 & 촬영 버튼
                        imagePreviewSection
                            .padding(.top, 12)
                        
                        // 스캔된 메뉴 리스트
                        scannedMenuSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 220) // 하단 Cart 바에 가려지지 않도록 여백 확보
                }
            }
            
            // 하단 반투명 Liquid Glass 장바구니 바
            if !cartItems.isEmpty {
                bottomCartBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: cartItems)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showCartDetails) {
            CartDetailsView(
                cartItems: $cartItems,
                serviceRate: $serviceRate,
                taxRate: $taxRate,
                cardRate: $cardRate,
                budgetKRW: budgetKRW
            )
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            guard let image = newValue else { return }
            processMenuImage(image)
        }
    }
    
    // MARK: - UI Components
    
    // 1. 상단 Budget Bar (Liquid Glass 인터페이스)
    private var topBudgetBar: some View {
        HStack {
            Text("Budget:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 탭하면 넘패드로 직접 금액 입력
            HStack(spacing: 2) {
                TextField("예산 입력", text: $budgetInput)
                    .keyboardType(.numberPad)
                    .focused($isBudgetFocused)
                    .font(.title3.bold())
                    .frame(minWidth: 60, maxWidth: 110)
                    .multilineTextAlignment(.leading)
                    .onChange(of: budgetInput) { _, newValue in
                        // 숫자만 필터링
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            budgetInput = filtered
                        }
                        if let newBudget = Int(filtered) {
                            budgetKRW = newBudget
                        }
                    }
                
                Text("원")
                    .font(.title3.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.04))
            .cornerRadius(8)
            
            Spacer()
            
            // 키보드가 올라왔을 때 닫기(완료) 버튼 노출
            if isBudgetFocused {
                Button("완료") {
                    isBudgetFocused = false
                    if let val = Int(budgetInput) {
                        budgetKRW = val
                    } else {
                        budgetInput = "\(budgetKRW)"
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(.blue)
                .padding(.trailing, 4)
            }
            
            Text("🇰🇷")
                .font(.title2)
                .padding(6)
                .background(Circle().fill(Color.white.opacity(0.4)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlassCard(cornerRadius: 16)
        
    }
    
    // 2. 이미지 프리뷰 섹션
    private var imagePreviewSection: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 200)
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(18)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("메뉴판을 촬영해 주세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isProcessing {
                    ProgressView("메뉴 분석 중...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            
            // Retake / 촬영 버튼
            Button(action: { showImagePicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: selectedImage == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                    Text(selectedImage == nil ? "Scan" : "Retake")
                }
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(12)
        }
    }
    
    // 3. 스캔된 메뉴 리스트
    private var scannedMenuSection: some View {
        VStack(spacing: 10) {
            ForEach(scannedItems) { item in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.rawName)
                                .font(.body.bold())
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
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatIDR(item.localPrice))
                            .font(.subheadline.bold())
                        Text(formatKRW(calculator.convertToKRW(localAmount: item.localPrice)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                    
                    // 담기 (+) 버튼
                    Button(action: { addToCart(item) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .liquidGlassCard(cornerRadius: 16) // 글래스모피즘 적용
            }
        }
    }
    
    // 4. 하단 Liquid Glass 장바구니 바
    private var bottomCartBar: some View {
        VStack(spacing: 12) {
            // 장바구니 담긴 아이템 요약 목록 (최대 3개 미리보기)
            // 장바구니 담긴 아이템 요약 목록 (수량 -, + 조절 추가)
            VStack(spacing: 8) {
                ForEach(cartItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.rawName)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text("(\(item.translatedName))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // 항목별 금액
                        Text(formatKRW(calculator.convertToKRW(localAmount: item.localPrice * Double(item.count))))
                            .font(.caption.bold())
                            .padding(.trailing, 6)
                        
                        // [-] 수량 [+] 컨트롤러
                        HStack(spacing: 8) {
                            Button(action: { decrementItem(item) }) {
                                Image(systemName: item.count == 1 ? "trash" : "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(item.count == 1 ? .red : .primary)
                                    .frame(width: 24, height: 24)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(Circle())
                            }
                            
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .frame(minWidth: 16)
                            
                            Button(action: { incrementItem(item) }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 24, height: 24)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 4)
            
            
            // 소계 및 아이템 개수 캡슐
            HStack(spacing: 10) {
                Text("Sum: \(formatKRW(calculator.convertToKRW(localAmount: calculationResult.subtotal)))")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                
                Text("\(totalItemCount) items")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            // 최종 결제 예정 금액 및 예산 초과 경고
            HStack {
                Text("Pay: \(formatKRW(calculationResult.grandTotalKRW))")
                    .font(.headline)
                    .bold()
                
                if isOverBudget {
                    HStack(spacing: 4) {
                        Text("🚨")
                        Text("(+\(formatKRW(overBudgetAmount)))")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // 액션 버튼 (Show Details / Reset Cart)
            HStack(spacing: 10) {
                Button(action: { showCartDetails = true }) {
                    Text("Show Details")
                        .font(.subheadline.bold())
                        .foregroundColor(.indigo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.indigo.opacity(0.15))
                        .cornerRadius(12)
                }
                
                Button(action: { cartItems.removeAll() }) {
                    Text("Reset Cart")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Logic Helpers
    
    private func addToCart(_ item: MenuItem) {
        if let index = cartItems.firstIndex(where: { $0.rawName == item.rawName }) {
            cartItems[index].count += 1
        } else {
            var newItem = item
            newItem.count = 1
            cartItems.append(newItem)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func processMenuImage(_ image: UIImage) {
        isProcessing = true
        scannedItems.removeAll()
        
        // recognizeText -> processImage로 변경, parseMenuItems -> parseElements로 연결
        ocrService.processImage(image) { elements in
            let parsed = self.parserService.parseElements(elements)
            self.scannedItems = parsed
            self.isProcessing = false
        }
    }
    
    private func formatIDR(_ amount: Double) -> String {
        let intAmount = Int(amount)
        if intAmount % 1000 == 0 {
            return "\(intAmount / 1000)K"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = "."
            let formattedNumber = formatter.string(from: NSNumber(value: intAmount)) ?? "\(intAmount)"
            return "Rp \(formattedNumber)"
        }
    }
    
    // ContentView 내부 하단에 원화 포맷터 추가
    private func formatKRW(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "원"
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
                // 1개일 때 마이너스를 누르면 장바구니에서 제거
                cartItems.remove(at: index)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial) // 뒤 배경 투과 블러
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                // 모서리 빛 반사 (Rim Light) 효과
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    ContentView(mockItems: [
        MenuItem(
            rawName: "Sop Buntut",
            translatedName: "소꼬리 맑은 탕",
            category: "육류",
            localPrice: 85000,
            count: 1
        ),
        MenuItem(
            rawName: "Nasi Goreng Seafood",
            translatedName: "모둠 해산물 볶음밥",
            category: "식사류",
            localPrice: 45000,
            count: 2
        ),
        MenuItem(
            rawName: "Ayam Geprek Sambal Matah",
            translatedName: "발리식 생삼발 양념 바삭튀김 닭고기",
            category: "육류",
            localPrice: 38000,
            count: 0
        ),
        MenuItem(
            rawName: "Tumis Kangkung",
            translatedName: "모닝글로리(공심채) 볶음",
            category: "채소류",
            localPrice: 25000,
            count: 1
        ),
        MenuItem(
            rawName: "Es Teh Manis",
            translatedName: "달콤한 아이스티",
            category: "음료",
            localPrice: 10000,
            count: 3
        )
    ])
}
