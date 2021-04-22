import { StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import React, { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import Colors from 'src/constants/colors'
import Icon from 'react-native-vector-icons/FontAwesome'
import { requestRecordAudioPermission } from 'src/audio/permissions'
import { PorcupineManager } from '@picovoice/porcupine-react-native'

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
    backgroundColor: Colors.darkBlueGrey,
  },
  button: {
    backgroundColor: Colors.lightRed,
    width: 320,
    height: 320,
    borderRadius: 160,
    borderWidth: 8,
    borderColor: Colors.red,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
    flexDirection: 'column',
  },
  buttonDisabled: {
    borderColor: Colors.green,
    backgroundColor: Colors.lightGreen,
  },
  buttonText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.darkBlueGrey,
    marginTop: 32,
  },
  noAudioPermission: {
    fontSize: 64,
    fontWeight: 'bold',
    color: Colors.red,
    marginTop: 32,
    textAlign: 'center',
  },
  icon: {
    paddingTop: 16,
  },
})

export function AudioAssistant() {
  const { t } = useTranslation()
  const [listenStatus, setListenStatus] = useState(false)
  const [hasPermission, setHasPermission] = useState(false)
  const [porcupineManager, setPorcupineManager] = useState<PorcupineManager>()
  requestRecordAudioPermission().then((permission: boolean) => setHasPermission(permission))

  const keywords = ['picovoice', 'porcupine']
  function detectionCallback(keywordIndex: number) {
    console.log('detectionCallback', keywords[keywordIndex])
  }

  useEffect(() => {
    PorcupineManager.fromKeywords(keywords, detectionCallback).then((pm: PorcupineManager) => {
      setPorcupineManager(pm)
    })
  }, [])

  async function toggleListener() {
    if (listenStatus) {
      const didStop = await porcupineManager?.stop()
      if (didStop) {
        setListenStatus(false)
      }
      setListenStatus(!listenStatus)
    } else {
      const didStart = await porcupineManager?.start()
      if (didStart) {
        setListenStatus(true)
      }
    }
  }

  return (
    <View style={styles.container}>
      {hasPermission ? (
        <TouchableOpacity
          style={listenStatus ? styles.button : [styles.button, styles.buttonDisabled]}
          onPress={toggleListener}>
          <Icon
            style={styles.icon}
            name={'assistive-listening-systems'}
            size={128}
            color={listenStatus ? Colors.red : Colors.green}
          />
          <Text style={styles.buttonText}>
            {listenStatus ? t('stopListening') : t('startListening')}
          </Text>
        </TouchableOpacity>
      ) : (
        <Text style={styles.noAudioPermission}>{t('noAudioPermission')}</Text>
      )}
    </View>
  )
}
