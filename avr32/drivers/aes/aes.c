/*****************************************************************************
 *
 * \file
 *
 * \brief AES software driver for AVR32 UC3.
 *
 * This file defines a useful set of functions for the AES on AVR32 devices.
 *
 * Copyright (c) 2014-2018 Microchip Technology Inc. and its subsidiaries.
 *
 * \asf_license_start
 *
 * \page License
 *
 * Subject to your compliance with these terms, you may use Microchip
 * software and any derivatives exclusively with Microchip products.
 * It is your responsibility to comply with third party license terms applicable
 * to your use of third party software (including open source software) that
 * may accompany Microchip software.
 *
 * THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES,
 * WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE,
 * INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY,
 * AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT WILL MICROCHIP BE
 * LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, INCIDENTAL OR CONSEQUENTIAL
 * LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND WHATSOEVER RELATED TO THE
 * SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS BEEN ADVISED OF THE
 * POSSIBILITY OR THE DAMAGES ARE FORESEEABLE.  TO THE FULLEST EXTENT
 * ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN ANY WAY
 * RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
 * THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *
 * \asf_license_stop
 *
 *****************************************************************************/
/*
 * Support and FAQ: visit <a href="https://www.microchip.com/support/">Microchip Support</a>
 */


#include "aes.h"


// Counter measure key in the AES_MR register.
#define AES_CKEY      0xE




void aes_configure( volatile avr32_aes_t *aes, const aes_config_t *pAesConfig )
{
  aes->mr = ((pAesConfig->ProcessingMode << AVR32_AES_MR_CIPHER_OFFSET) & AVR32_AES_MR_CIPHER_MASK) |
            ((pAesConfig->ProcessingDelay << AVR32_AES_MR_PROCDLY_OFFSET) & AVR32_AES_MR_PROCDLY_MASK) |
            ((pAesConfig->StartMode << AVR32_AES_MR_SMOD_OFFSET) & AVR32_AES_MR_SMOD_MASK) |
            ((pAesConfig->KeySize << AVR32_AES_MR_KEYSIZE_OFFSET) & AVR32_AES_MR_KEYSIZE_MASK) |
            ((pAesConfig->OpMode << AVR32_AES_MR_OPMOD_OFFSET) & AVR32_AES_MR_OPMOD_MASK) |
            ((pAesConfig->LodMode << AVR32_AES_MR_LOD_OFFSET) & AVR32_AES_MR_LOD_MASK) |
            ((pAesConfig->CFBSize << AVR32_AES_MR_CFBS_OFFSET) & AVR32_AES_MR_CFBS_MASK) |
            ((pAesConfig->CounterMeasureMask << AVR32_AES_MR_CTYPE_OFFSET) & AVR32_AES_MR_CTYPE_MASK) |
            ((AES_CKEY << AVR32_AES_MR_CKEY_OFFSET) & AVR32_AES_MR_CKEY_MASK);
}


void aes_isr_configure( volatile avr32_aes_t *aes, const aes_isrconfig_t *pAesIsrConfig )
{
  bool global_interrupt_enabled = Is_global_interrupt_enabled();


  // Enable the appropriate interrupts.
  aes->ier = pAesIsrConfig->datrdy << AVR32_AES_IER_DATRDY_OFFSET |
             pAesIsrConfig->urad << AVR32_AES_IER_URAD_OFFSET ;
  // Disable the appropriate interrupts.
  if (global_interrupt_enabled) Disable_global_interrupt();
  aes->idr = (~(pAesIsrConfig->datrdy) & 1) << AVR32_AES_IDR_DATRDY_OFFSET |
             (~(pAesIsrConfig->urad) & 1) << AVR32_AES_IDR_URAD_OFFSET ;

  if (global_interrupt_enabled) Enable_global_interrupt();
}


unsigned int aes_get_status( volatile avr32_aes_t *aes )
{
  return(aes->isr);
}


void aes_set_key( volatile avr32_aes_t *aes, const unsigned int *pKey)
{
  unsigned long int volatile *pTempo = &(aes->keyw1r);
  unsigned char       keylen = 0;


  switch((aes->mr & AVR32_AES_MR_KEYSIZE_MASK) >> AVR32_AES_MR_KEYSIZE_OFFSET)
  {
    case 0: // 128bit cryptographic key
      keylen = 4;
      break;
    case 1: // 192bit cryptographic key
      keylen = 6;
      break;
    case 2: // 256bit cryptographic key
      keylen = 8;
      break;
    default:
      break;
  }
  for( ; keylen > 0; keylen--)
    *pTempo++ = *pKey++;
}


void aes_set_initvector( volatile avr32_aes_t *aes, const unsigned int *pVector)
{
  unsigned long int volatile *pTempo = &(aes->iv1r);
  int i;

  for(i=0; i<4; i++)
    *pTempo++ = *pVector++;
}


void aes_write_inputdata( volatile avr32_aes_t *aes, const unsigned int *pIn)
{
  unsigned long int volatile *pTempo = &(aes->idata1r);
  unsigned char inlen = 4;


  if(AES_CFB_MODE == ((aes->mr & AVR32_AES_MR_OPMOD_MASK) >> AVR32_AES_MR_OPMOD_OFFSET))
  {
    switch((aes->mr & AVR32_AES_MR_CFBS_MASK) >> AVR32_AES_MR_CFBS_OFFSET)
    {
      case 1: // 64bit CFB data size
        inlen = 2;
        break;
      case 2: // 32bit CFB data size
      case 3: // 16bit CFB data size
      case 4: // 8bit CFB data size
        inlen = 1;
        break;
      default:
        break;
    }
  }
  for(; inlen > 0; inlen--)
    *pTempo++ = *pIn++;
}


void aes_read_outputdata( volatile avr32_aes_t *aes, unsigned int *pOut)
{
  unsigned long int const volatile *pTempo = &(aes->odata1r);
  unsigned char outlen = 4;


  if(AES_CFB_MODE == ((aes->mr & AVR32_AES_MR_OPMOD_MASK) >> AVR32_AES_MR_OPMOD_OFFSET))
  {
    switch((aes->mr & AVR32_AES_MR_CFBS_MASK) >> AVR32_AES_MR_CFBS_OFFSET)
    {
      case 1: // 64bit CFB data size
        outlen = 2;
        break;
      case 2: // 32bit CFB data size
      case 3: // 16bit CFB data size
      case 4: // 8bit CFB data size
        outlen = 1;
        break;
      default:
        break;
    }
  }
  for(; outlen > 0; outlen--)
    *pOut++ = *pTempo++;
}
