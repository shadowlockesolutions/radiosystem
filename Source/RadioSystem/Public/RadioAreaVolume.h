#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RadioAreaVolume.generated.h"

class UBoxComponent;

UCLASS()
class RADIOSYSTEM_API ARadioAreaVolume : public AActor
{
    GENERATED_BODY()

public:
    ARadioAreaVolume();

    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

    bool SupportsStationAtLocation(FName StationId, const FVector& Location) const;

private:
    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<UBoxComponent> AreaBounds;

    UPROPERTY(EditAnywhere, Category = "Radio")
    TArray<FName> SupportedStations;
};
