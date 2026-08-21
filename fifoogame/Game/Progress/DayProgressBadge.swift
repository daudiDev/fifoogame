//
//  DayProgressBadge.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/21/26.
//


import SwiftUI


struct DayProgressBadge: View {

    @ObservedObject
    var store:
        GameStore


    var body: some View {

        HStack(
            spacing:
                6
        ) {

            Image(
                systemName:
                    progressSymbol
            )


            Text(
                store
                    .currentProgressPercent,
                format:
                    .number
                    .precision(
                        .fractionLength(
                            0
                        )
                    )
            )


            Text("%")
        }
        .fontWeight(
            .semibold
        )
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            8
        )
        .background(
            .ultraThinMaterial,
            in:
                Capsule()
        )
    }


    private var progressSymbol:
        String {

        let change =
            store
                .progressState
                .totalChange


        if change > 0 {

            return "arrow.up.right"
        }


        if change < 0 {

            return "arrow.down.left"
        }


        return "minus"
    }
}