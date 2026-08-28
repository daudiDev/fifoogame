//
//  DayMapDatePickerView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//


import SwiftUI

struct DayMapDatePickerView: View {

    private let socketManager =
        SocketManager.shared

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var draftDate: Date


    init() {

        _draftDate =
            State(
                initialValue:
                    SocketManager.shared.selectedDayMapDate
            )
    }


    var body: some View {

        NavigationStack {

            VStack(
                spacing: 16
            ) {

                HStack(
                    spacing: 12
                ) {

                    Button {

                        moveDraftDay(
                            by: -1
                        )

                    } label: {

                        Image(
                            systemName: "chevron.left"
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )
                    }
                    .buttonStyle(.bordered)

                    Button {

                        draftDate =
                            Date()

                    } label: {

                        Text("Today")
                            .frame(
                                minHeight: 44
                            )
                    }
                    .buttonStyle(.bordered)

                    Button {

                        moveDraftDay(
                            by: 1
                        )

                    } label: {

                        Image(
                            systemName: "chevron.right"
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )
                    }
                    .buttonStyle(.bordered)
                }

                DatePicker(
                    "Day Map Date",
                    selection:
                        $draftDate,
                    displayedComponents:
                        .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()

                if socketManager.isDayMapLoading {

                    ProgressView(
                        "Loading Day Map…"
                    )
                    .font(.footnote)
                }

                Spacer(
                    minLength: 0
                )
            }
            .padding(.horizontal)
            .navigationTitle(
                "Choose Day"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Open") {

                        socketManager
                            .selectDayMapDate(
                                draftDate
                            )

                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }


    private func moveDraftDay(
        by offset: Int
    ) {

        let timeZone =
            TimeZone(
                identifier:
                    socketManager
                        .gameStore
                        .clockTimeZoneIdentifier
            )
            ?? .current

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone

        guard let date =
            calendar.date(
                byAdding: .day,
                value: offset,
                to: draftDate
            )
        else {
            return
        }

        draftDate =
            date
    }
}
