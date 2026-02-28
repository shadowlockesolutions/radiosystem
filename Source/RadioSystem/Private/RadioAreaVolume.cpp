#include "RadioAreaVolume.h"

#include "Components/BoxComponent.h"
#include "RadioSubsystem.h"

ARadioAreaVolume::ARadioAreaVolume()
{
    PrimaryActorTick.bCanEverTick = false;

    AreaBounds = CreateDefaultSubobject<UBoxComponent>(TEXT("AreaBounds"));
    SetRootComponent(AreaBounds);
    AreaBounds->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void ARadioAreaVolume::BeginPlay()
{
    Super::BeginPlay();

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (URadioSubsystem* RadioSubsystem = GameInstance->GetSubsystem<URadioSubsystem>())
        {
            RadioSubsystem->RegisterArea(this);
        }
    }
}

void ARadioAreaVolume::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (URadioSubsystem* RadioSubsystem = GameInstance->GetSubsystem<URadioSubsystem>())
        {
            RadioSubsystem->UnregisterArea(this);
        }
    }

    Super::EndPlay(EndPlayReason);
}

bool ARadioAreaVolume::SupportsStationAtLocation(FName StationId, const FVector& Location) const
{
    return SupportedStations.Contains(StationId) && AreaBounds->IsOverlappingPoint(Location);
}
