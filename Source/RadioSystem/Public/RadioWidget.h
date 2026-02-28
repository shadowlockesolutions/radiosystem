#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "RadioWidget.generated.h"

class URadioComponent;
class UButton;
class USlider;
class UTextBlock;

UCLASS()
class RADIOSYSTEM_API URadioWidget : public UUserWidget
{
    GENERATED_BODY()

public:
    void BindRadio(URadioComponent* InRadioComponent);

protected:
    virtual void NativeConstruct() override;

private:
    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UButton> NextStationButton;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UButton> PreviousStationButton;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<USlider> VolumeSlider;

    UPROPERTY(meta = (BindWidget))
    TObjectPtr<UTextBlock> StationNameLabel;

    UPROPERTY()
    TObjectPtr<URadioComponent> RadioComponent;

    UFUNCTION()
    void HandleNextStation();

    UFUNCTION()
    void HandlePreviousStation();

    UFUNCTION()
    void HandleVolumeChanged(float NewValue);

    UFUNCTION()
    void HandleStationChanged(FName NewStationId);
};
