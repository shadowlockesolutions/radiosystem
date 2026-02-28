#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "RadioTypes.h"
#include "RadioSubsystem.generated.h"

class ARadioAreaVolume;

UCLASS()
class RADIOSYSTEM_API URadioSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    virtual void Initialize(FSubsystemCollectionBase& Collection) override;

    const TArray<FRadioStationDefinition>& GetStations() const { return Stations; }
    bool ResolveStation(FName StationId, FRadioStationDefinition& OutStation) const;

    FRadioTrackSelection ResolveCurrentTrack(FName StationId, float ServerWorldTimeSeconds) const;

    void RegisterArea(ARadioAreaVolume* Area);
    void UnregisterArea(ARadioAreaVolume* Area);

    bool IsStationAudibleAtLocation(FName StationId, const FVector& Location) const;

private:
    UPROPERTY()
    TArray<FRadioStationDefinition> Stations;

    UPROPERTY()
    TArray<TObjectPtr<ARadioAreaVolume>> ActiveAreas;

    void BuildDefaultStations();
    static int32 PickWeightedTrack(const TArray<FRadioTrack>& Tracks, float Seed);
};
