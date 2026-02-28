#include "RadioActor.h"

#include "Components/StaticMeshComponent.h"
#include "Components/WidgetComponent.h"
#include "RadioComponent.h"

ARadioActor::ARadioActor()
{
    PrimaryActorTick.bCanEverTick = false;

    RadioMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("RadioMesh"));
    SetRootComponent(RadioMesh);

    RadioComponent = CreateDefaultSubobject<URadioComponent>(TEXT("RadioComponent"));

    RadioWidgetComponent = CreateDefaultSubobject<UWidgetComponent>(TEXT("RadioWidget"));
    RadioWidgetComponent->SetupAttachment(RadioMesh);
    RadioWidgetComponent->SetWidgetSpace(EWidgetSpace::Screen);
    RadioWidgetComponent->SetDrawSize(FVector2D(340.0f, 120.0f));
}
