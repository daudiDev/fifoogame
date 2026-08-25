//
//  UserProgressDataView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
//

import SwiftUI

struct UserProgressDataView: View {
    @Binding var isShowingProgressDataView: Bool
    var body: some View {
        VStack {
            Text("Progress Data View")
                .padding(.top, 70)
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isShowingProgressDataView.toggle()
                }
            }) {
                
                Text("Close Page")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
                    .padding(.vertical, 20)
                
            }
            
        } //vs
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 5).fill(.ultraThickMaterial))
        .ignoresSafeArea()
        
    }
}

