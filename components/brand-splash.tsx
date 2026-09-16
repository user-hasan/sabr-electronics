import { useEffect, useRef } from "react";
import { Animated, Image, StyleSheet, Text, View } from "react-native";

export function BrandSplash({ onDone }: { onDone: () => void }) {
  const opacity = useRef(new Animated.Value(1)).current;
  const logoScale = useRef(new Animated.Value(0.72)).current;
  const lineWidth = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.parallel([
        Animated.spring(logoScale, { toValue: 1, friction: 7, tension: 55, useNativeDriver: true }),
        Animated.timing(lineWidth, { toValue: 1, duration: 850, useNativeDriver: false }),
      ]),
      Animated.delay(420),
      Animated.timing(opacity, { toValue: 0, duration: 260, useNativeDriver: true }),
    ]).start(onDone);
  }, [lineWidth, logoScale, opacity, onDone]);

  return (
    <Animated.View pointerEvents="none" style={[styles.root, { opacity }]}>
      <Animated.View style={{ transform: [{ scale: logoScale }] }}>
        <Image source={require("@/assets/images/saber-se-monogram.png")} style={styles.logo} resizeMode="contain" />
      </Animated.View>
      <View style={styles.brandBlock}>
        <Text style={styles.brand}>Saber Electronics</Text>
        <Text style={styles.tagline}>صيانة إلكترونيات متخصصة</Text>
        <Animated.View style={[styles.rule, { width: lineWidth.interpolate({ inputRange: [0, 1], outputRange: [0, 190] }) }]} />
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: { ...StyleSheet.absoluteFillObject, zIndex: 100, backgroundColor: "#FFFFFF", alignItems: "center", justifyContent: "center" },
  logo: { width: 160, height: 160 },
  brandBlock: { alignItems: "center", marginTop: 18 },
  brand: { color: "#0E2238", fontSize: 25, fontWeight: "900", letterSpacing: 0.5 },
  tagline: { color: "#0E2238", fontSize: 13, marginTop: 8, fontWeight: "700" },
  rule: { height: 3, borderRadius: 2, backgroundColor: "#0E2238", marginTop: 18 },
});
