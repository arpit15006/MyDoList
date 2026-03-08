//
//  AnimatedCheckbox.swift
//  MyDoList
//
//  Created by Arpit Patel on 04/12/25.
//

import SwiftUI

struct AnimatedCheckbox: View {
    @Binding var isChecked: Bool
    let size: CGFloat
    let color: Color
    let onToggle: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    init(isChecked: Binding<Bool>, size: CGFloat = 24, color: Color = .blue, onToggle: @escaping () -> Void = {}) {
        self._isChecked = isChecked
        self.size = size
        self.color = color
        self.onToggle = onToggle
    }
    
    var body: some View {
        Button {
            withAnimation(.smoothSpring) {
                isChecked.toggle()
                scale = 1.2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.smoothSpring) {
                    scale = 1.0
                }
            }
            
            onToggle()
        } label: {
            ZStack {
                Circle()
                    .stroke(isChecked ? color : Color.gray.opacity(0.5), lineWidth: 2)
                    .frame(width: size, height: size)
                
                if isChecked {
                    Circle()
                        .fill(color)
                        .frame(width: size - 4, height: size - 4)
                        .transition(.scale.combined(with: .opacity))
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.6, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .scaleEffect(scale)
        .animation(.smoothSpring, value: isChecked)
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    let systemImage: String
    let color: Color
    
    @State private var isPressed = false
    
    init(systemImage: String = "plus", color: Color = .blue, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color.gradient)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 2 : 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 30) {
        AnimatedCheckbox(isChecked: .constant(false))
        AnimatedCheckbox(isChecked: .constant(true))
        FloatingActionButton(systemImage: "plus", color: .orange) {}
    }
    .padding()
}