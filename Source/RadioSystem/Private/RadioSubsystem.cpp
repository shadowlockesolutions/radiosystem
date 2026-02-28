#include "RadioSubsystem.h"

#include "RadioAreaVolume.h"
#include "Kismet/GameplayStatics.h"

void URadioSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
    Super::Initialize(Collection);
    BuildDefaultStations();
}

bool URadioSubsystem::ResolveStation(FName StationId, FRadioStationDefinition& OutStation) const
{
    const FRadioStationDefinition* Station = Stations.FindByPredicate(
        [&](const FRadioStationDefinition& Candidate)
        {
            return Candidate.StationId == StationId;
        });

    if (!Station)
    {
        return false;
    }

    OutStation = *Station;
    return true;
}

FRadioTrackSelection URadioSubsystem::ResolveCurrentTrack(FName StationId, float ServerWorldTimeSeconds) const
{
    FRadioTrackSelection Selection;

    FRadioStationDefinition Station;
    if (!ResolveStation(StationId, Station) || Station.Tracks.IsEmpty())
    {
        return Selection;
    }

    const int32 WeightedTrack = PickWeightedTrack(Station.Tracks, ServerWorldTimeSeconds + GetTypeHash(StationId));
    if (!Station.Tracks.IsValidIndex(WeightedTrack) || !Station.Tracks[WeightedTrack].Sound)
    {
        return Selection;
    }

    const float TrackLength = Station.Tracks[WeightedTrack].Sound->GetDuration();
    Selection.TrackIndex = WeightedTrack;
    Selection.PlaybackStartSeconds = FMath::Fmod(ServerWorldTimeSeconds, TrackLength > 0.0f ? TrackLength : 1.0f);
    return Selection;
}

void URadioSubsystem::RegisterArea(ARadioAreaVolume* Area)
{
    ActiveAreas.AddUnique(Area);
}

void URadioSubsystem::UnregisterArea(ARadioAreaVolume* Area)
{
    ActiveAreas.RemoveSingleSwap(Area);
}

bool URadioSubsystem::IsStationAudibleAtLocation(FName StationId, const FVector& Location) const
{
    FRadioStationDefinition Station;
    if (!ResolveStation(StationId, Station))
    {
        return false;
    }

    if (Station.StationType == ERadioStationType::GlobalMusic || Station.StationType == ERadioStationType::GlobalBroadcast)
    {
        return true;
    }

    for (const ARadioAreaVolume* Area : ActiveAreas)
    {
        if (IsValid(Area) && Area->SupportsStationAtLocation(StationId, Location))
        {
            return true;
        }
    }

    return false;
}

void URadioSubsystem::BuildDefaultStations()
{
    Stations.Reset();

    FRadioStationDefinition MusicStation;
    MusicStation.StationId = TEXT("Music_Global");
    MusicStation.DisplayName = FText::FromString(TEXT("107.7 Radiation FM"));
    MusicStation.StationType = ERadioStationType::GlobalMusic;
    MusicStation.DefaultVolume = 0.85f;
    Stations.Add(MusicStation);

    FRadioStationDefinition NewsStation;
    NewsStation.StationId = TEXT("Broadcast_Global");
    NewsStation.DisplayName = FText::FromString(TEXT("88.5 Civil Alert"));
    NewsStation.StationType = ERadioStationType::GlobalBroadcast;
    NewsStation.DefaultVolume = 0.75f;
    Stations.Add(NewsStation);

    FRadioStationDefinition RegionalStation;
    RegionalStation.StationId = TEXT("Regional_Industrial");
    RegionalStation.DisplayName = FText::FromString(TEXT("95.2 Factory Beats"));
    RegionalStation.StationType = ERadioStationType::RegionalMusic;
    Stations.Add(RegionalStation);
}

int32 URadioSubsystem::PickWeightedTrack(const TArray<FRadioTrack>& Tracks, float Seed)
{
    if (Tracks.IsEmpty())
    {
        return INDEX_NONE;
    }

    float TotalWeight = 0.0f;
    for (const FRadioTrack& Track : Tracks)
    {
        TotalWeight += FMath::Max(0.01f, Track.Weight);
    }

    FRandomStream Random(FMath::RoundToInt(Seed * 100.0f));
    float Running = 0.0f;
    const float Target = Random.FRandRange(0.0f, TotalWeight);

    for (int32 Index = 0; Index < Tracks.Num(); ++Index)
    {
        Running += FMath::Max(0.01f, Tracks[Index].Weight);
        if (Target <= Running)
        {
            return Index;
        }
    }

    return Tracks.Num() - 1;
}
