#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RadioActor.generated.h"

class UStaticMeshComponent;
class URadioComponent;
class UWidgetComponent;

UCLASS()
class RADIOSYSTEM_API ARadioActor : public AActor
{
    GENERATED_BODY()

public:
    ARadioActor();

private:
    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<UStaticMeshComponent> RadioMesh;

    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<URadioComponent> RadioComponent;

    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<UWidgetComponent> RadioWidgetComponent;
};
