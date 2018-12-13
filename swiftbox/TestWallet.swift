//
//  TestWallet.swift
//  swiftbox
//
//  Created by hsiaosiyuan on 2018/12/13.
//  Copyright © 2018 hsiaosiyuan. All rights reserved.
//

import OntSwift

class TestWallet {
  public static let data = """
  {"name":"MyWallet","version":"1.1","scrypt":{"p":8,"n":16384,"r":8,"dkLen":64},"accounts":[{"address":"ASSxYHNSsh4FdF2iNvHdh3Np2sgWU21hfp","enc-alg":"aes-256-gcm","key":"t2Kk2jNL4BAoXlYn309DKfxogxJRNvsJ8+GG4kiMB+UvWGXEilYRzfIYeNZbfVbu","algorithm":"ECDSA","salt":"CdRa1hTiOaVESNfJJmcMNw==","parameters":{"curve":"P-256"},"label":"","publicKey":"0344ea636caaebf23c7cec2219a75bd6260f891413467922975447ba57f3c824c6","signatureScheme":"SHA256withECDSA","isDefault":true,"lock":false},{"address":"AL9PtS6F8nue5MwxhzXCKaTpRb3yhtsix5","enc-alg":"aes-256-gcm","key":"vwIgX3qJO+1XikdPAfjAu/clsgS2l2xkEWsRR9XZQ8OyFViX+r/6Yq+cV0wnKQUM","algorithm":"SM2","salt":"xzvrFkHAgsEeX64V+4mpLw==","parameters":{"curve":"sm2p256v1"},"label":"","publicKey":"131403a9b89a0443ded240c3dee97221353d000d0dc905b7c085f4ef558b234a75e122","signatureScheme":"SM3withSM2","isDefault":false,"lock":false}]}
  """
  
  public static func w() throws -> Wallet {
    return try JSONDecoder().decode(Wallet.self, from: data.data(using: .utf8)!)
  }
}
