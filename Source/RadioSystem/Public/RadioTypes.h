#pragma once

#include "CoreMinimal.h"
#include "Engine/DataTable.h"
#include "RadioTypes.generated.h"

UENUM(BlueprintType)
enum class ERadioStationType : uint8
{
    GlobalMusic,
    GlobalBroadcast,
    RegionalMusic,
    RegionalBroadcast
};

USTRUCT(BlueprintType)
struct FRadioTrack
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, Category = "Radio")
    TObjectPtr<USoundBase> Sound = nullptr;

    UPROPERTY(EditAnywhere, Category = "Radio")
    float Weight = 1.0f;
};

USTRUCT(BlueprintType)
struct FRadioStationDefinition : public FTableRowBase
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, Category = "Radio")
    FName StationId = NAME_None;

    UPROPERTY(EditAnywhere, Category = "Radio")
    FText DisplayName;

    UPROPERTY(EditAnywhere, Category = "Radio")
    ERadioStationType StationType = ERadioStationType::GlobalMusic;

    UPROPERTY(EditAnywhere, Category = "Radio")
    float DefaultVolume = 0.8f;

    UPROPERTY(EditAnywhere, Category = "Radio")
    float TuningNoiseSeconds = 0.35f;

    UPROPERTY(EditAnywhere, Category = "Radio")
    TArray<FRadioTrack> Tracks;
};

USTRUCT()
struct FRadioTrackSelection
{
    GENERATED_BODY()

    int32 TrackIndex = INDEX_NONE;
    float PlaybackStartSeconds = 0.0f;
};
