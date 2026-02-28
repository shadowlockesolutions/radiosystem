#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "RadioVehicleInterface.generated.h"

class URadioComponent;

UINTERFACE(MinimalAPI)
class URadioVehicleInterface : public UInterface
{
    GENERATED_BODY()
};

class RADIOSYSTEM_API IRadioVehicleInterface
{
    GENERATED_BODY()

public:
    virtual URadioComponent* GetVehicleRadioComponent() const = 0;
};
