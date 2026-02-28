#include "RadioWidget.h"

#include "Components/Button.h"
#include "Components/Slider.h"
#include "Components/TextBlock.h"
#include "RadioComponent.h"

void URadioWidget::NativeConstruct()
{
    Super::NativeConstruct();

    if (NextStationButton)
    {
        NextStationButton->OnClicked.AddDynamic(this, &URadioWidget::HandleNextStation);
    }

    if (PreviousStationButton)
    {
        PreviousStationButton->OnClicked.AddDynamic(this, &URadioWidget::HandlePreviousStation);
    }

    if (VolumeSlider)
    {
        VolumeSlider->OnValueChanged.AddDynamic(this, &URadioWidget::HandleVolumeChanged);
    }
}

void URadioWidget::BindRadio(URadioComponent* InRadioComponent)
{
    RadioComponent = InRadioComponent;
    if (RadioComponent)
    {
        RadioComponent->OnStationChanged.AddDynamic(this, &URadioWidget::HandleStationChanged);
    }
}

void URadioWidget::HandleNextStation()
{
    if (RadioComponent)
    {
        RadioComponent->NextStation();
    }
}

void URadioWidget::HandlePreviousStation()
{
    if (RadioComponent)
    {
        RadioComponent->PreviousStation();
    }
}

void URadioWidget::HandleVolumeChanged(float NewValue)
{
    if (RadioComponent)
    {
        RadioComponent->SetMasterVolume(NewValue);
    }
}

void URadioWidget::HandleStationChanged(FName NewStationId)
{
    if (StationNameLabel)
    {
        StationNameLabel->SetText(FText::FromName(NewStationId));
    }
}
