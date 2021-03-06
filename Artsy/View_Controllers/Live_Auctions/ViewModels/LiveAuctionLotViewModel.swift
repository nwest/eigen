import Foundation
import Interstellar

// Represents a single lot view

enum LotState {
    case ClosedLot
    case LiveLot
    case UpcomingLot(distanceFromLive: Int)
}

protocol LiveAuctionLotViewModelType: class {
    func eventAtIndex(index: Int) -> LiveAuctionEventViewModel
    func computedLotStateSignal(auctionViewModel: LiveAuctionViewModelType) -> Signal<LotState>

    var lotArtist: String { get }
    var estimateString: String { get }
    var lotPremium: String { get }
    var lotName: String { get }
    var lotArtworkCreationDate: String? { get }
    var urlForThumbnail: NSURL { get }
    var urlForProfile: NSURL { get }
    var numberOfEvents: Int { get }
    var lotIndex: Int { get }
    var currentLotValue: UInt64 { get }
    var currentLotValueString: String { get }
    var numberOfBids: Int { get }
    var imageProfileSize: CGSize { get }
    var liveAuctionLotID: String { get }
    var reserveStatusString: String { get }

    var reserveStatusSignal: Signal<ARReserveStatus> { get }
    var askingPriceSignal: Signal<UInt64> { get }
    var startEventUpdatesSignal: Signal<NSDate> { get }
    var endEventUpdatesSignal: Signal<NSDate> { get }
    var newEventSignal: Signal<LiveAuctionEventViewModel> { get }
}

class LiveAuctionLotViewModel: NSObject, LiveAuctionLotViewModelType {

    private let model: LiveAuctionLot
    private var events = [LiveAuctionEventViewModel]()

    let reserveStatusSignal = Signal<ARReserveStatus>()
    let askingPriceSignal = Signal<UInt64>()

    let startEventUpdatesSignal = Signal<NSDate>()
    let endEventUpdatesSignal = Signal<NSDate>()
    let newEventSignal = Signal<LiveAuctionEventViewModel>()

    init(lot: LiveAuctionLot) {
        self.model = lot

        reserveStatusSignal.update(lot.reserveStatus)
        askingPriceSignal.update(lot.onlineAskingPriceCents)
    }
    func lotStateWithViewModel(viewModel: LiveAuctionViewModelType) -> LotState {
        guard let distance = viewModel.distanceFromCurrentLot(model) else {
            return .ClosedLot
        }
        if distance == 0 { return .LiveLot }
        if distance < 0 { return .ClosedLot }
        return .UpcomingLot(distanceFromLive: distance)
    }

    func computedLotStateSignal(auctionViewModel: LiveAuctionViewModelType) -> Signal<LotState> {
        return auctionViewModel
            .currentLotIDSignal
            .map { [weak self, weak auctionViewModel] currentLotID -> LotState in
                guard let sSelf = self, sAuctionViewModel = auctionViewModel else { return .ClosedLot }
                return sSelf.lotStateWithViewModel(sAuctionViewModel)
            }
    }

    var numberOfBids: Int {
        return events.filter { $0.isBid }.count
    }

    var urlForThumbnail: NSURL {
        return model.urlForThumbnail()
    }

    var urlForProfile: NSURL {
        return model.urlForProfile()
    }

    var imageProfileSize: CGSize {
        return model.imageProfileSize()
    }

    var lotName: String {
        return model.artworkTitle
    }

    var lotArtworkCreationDate: String? {
        return model.artworkDate
    }

    var lotArtist: String {
        return model.artistName
    }

    var lotPremium: String {
        return "Premium: WIP"
    }

    var lotIndex: Int {
        return model.position
    }

    var liveAuctionLotID: String {
        return model.liveAuctionLotID
    }

    var currentLotValue: UInt64 {
        // TODO: is onlineAskingPriceCents correct? not sure from JSON
        //       maybe we need to look through the events for the last bid?
        return LiveAuctionBidViewModel.nextBidCents(model.onlineAskingPriceCents)
    }

    var currentLotValueString: String {
        return currentLotValue.convertToDollarString()
    }

    var estimateString: String {
        let low = NSNumber(unsignedLongLong: model.lowEstimateCents)
        let high = NSNumber(unsignedLongLong: model.highEstimateCents)
        return SaleArtwork.estimateStringForLowEstimate(low, highEstimateCents:high, currencySymbol: model.currencySymbol, currency: model.currency)
    }

    var eventIDs: [String] {
        return model.eventIDs
    }

    var numberOfEvents: Int {
        return events.count
    }
    
    func eventAtIndex(index: Int) -> LiveAuctionEventViewModel {
        return events[index]
    }

    var reserveStatusString: String {
        guard let status = reserveStatusSignal.peek() else {
            return "unknown reserve"
        }

        switch status {
        case .NoReserve:
            return "no reserve"
        case .ReserveMet:
            return "reserve met"
        case .ReserveNotMet:
            return "reserve not yet met"
        }
    }

    func updateReserveStatus(reserveStatusString: String) {
        let updated = model.updateReserveStatusWithString(reserveStatusString)
        
        if updated {
            reserveStatusSignal.update(model.reserveStatus)
        }
    }

    func updateOnlineAskingPrice(askingPrice: UInt64) {
        let updated = model.updateOnlineAskingPrice(askingPrice)

        if updated {
            askingPriceSignal.update(askingPrice)
        }
    }

    func addEvents(events: [LiveEvent]) {
        startEventUpdatesSignal.update(NSDate())
        defer { endEventUpdatesSignal.update(NSDate()) }

        model.addEvents(events.map { $0.eventID })
        let newEvents = events.map { LiveAuctionEventViewModel(event: $0) }
        newEvents.forEach { event in
            newEventSignal.update(event)
        }
        self.events += newEvents
    }
}

